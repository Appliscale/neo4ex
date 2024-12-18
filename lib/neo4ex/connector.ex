defmodule Neo4ex.Connector do
  @moduledoc """
  Module responsible for communication with the database engine
  """
  import Kernel, except: [send: 2]

  alias Neo4ex.Connector.Socket
  alias Neo4ex.Cypher

  alias Neo4ex.BoltProtocol
  alias Neo4ex.BoltProtocol.{Encoder, Decoder}

  # Chunk headers are 16-bit unsigned integers
  @chunk_size 16
  @noop <<0::size(@chunk_size)>>
  # since 4.3 there is support for version range during negotiation
  # so "4.4.1" actually means "4.4" plus one previous version "4.3"
  @supported_versions ["5.20.20", "4.4.3", "4.2.0", "4.0.0"]

  defmacro __using__(otp_app: app) do
    supported_versions = @supported_versions

    quote do
      use Supervisor

      @connector_opts Application.compile_env(unquote(app), __MODULE__, [])
      @debug_queries Keyword.get(@connector_opts, :debug) == true

      def start_link(opts) do
        Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
      end

      @impl true
      def init(opts) do
        opts = Keyword.merge(@connector_opts, opts)

        children = [
          %{
            id: BoltProtocol,
            start:
              {DBConnection, :start_link,
               [BoltProtocol, [{:versions, unquote(supported_versions)} | opts]]}
          }
        ]

        Supervisor.init(children, strategy: :one_for_one)
      end

      @doc """
      Executes Cypher query on the database and returns results.
      This function always reads all data and returns a list of results.
      If you need more control, use `stream/2`.
      """
      def run(%Cypher.Query{} = query, opts \\ []) do
        with {:ok, args} <- prepare_query(query, opts) do
          apply(DBConnection, :execute, args)
        end
      end

      @doc """
      Returns lazy enumerable that emits all results matching given query.
      It has to be ran inside transaction to read the data:
      ```
      stream = Connector.stream(query)
      Connector.transaction(fn ->
        Enum.to_list(stream)
      end)
      ```
      """
      def stream(%Cypher.Query{} = query, opts \\ []) do
        pool = connection_pool!()
        %Cypher.Stream{pool: pool, query: query}
      end

      def transaction(func) when is_function(func, 0) do
        pool = connection_pool!()
        Neo4ex.Connector.transaction(pool, [], fn _ -> func.() end)
      end

      def transaction(func) when is_function(func, 1) do
        pool = connection_pool!()
        Neo4ex.Connector.transaction(pool, [], func)
      end

      defp prepare_query(query, opts) do
        pool = connection_pool!()
        opts = Keyword.merge([debug: @debug_queries], opts)

        case DBConnection.prepare(pool, query, opts) do
          {:ok, query} -> {:ok, [pool, query, opts]}
          other -> other
        end
      end

      defp connection_pool!() do
        case Supervisor.which_children(__MODULE__) do
          [{_, pool, _, [DBConnection]} | _] -> pool
          [] -> raise "Please add #{__MODULE__} to application Supervision tree"
        end
      end
    end
  end

  defmacro supported_versions() do
    @supported_versions
    |> Enum.flat_map(fn version ->
      [major, minor, range] = version |> String.split(".") |> Enum.map(&String.to_integer/1)

      for i <- minor..(minor - range) do
        Version.parse!("#{major}.#{i}.0")
      end
    end)
    |> Enum.uniq()
    |> Macro.escape()
  end

  @doc false
  def transaction(pool, opts, callback) when is_function(callback, 1) do
    checkout_or_transaction(:transaction, pool, opts, callback)
  end

  @doc false
  def reduce(pool, query, params, opts, acc, fun) do
    case get_conn(pool) do
      %DBConnection{conn_mode: :transaction} = conn ->
        DBConnection
        |> apply(:stream, [conn, query, params, opts])
        |> Enumerable.reduce(acc, fun)

      _ ->
        raise "cannot reduce stream outside of transaction"
    end
  end

  @doc false
  def into(pool, query, params, opts) do
    case get_conn(pool) do
      %DBConnection{conn_mode: :transaction} = conn ->
        DBConnection
        |> apply(:stream, [conn, query, params, opts])
        |> Collectable.into()

      _ ->
        raise "cannot collect into stream outside of transaction"
    end
  end

  def send_noop(%Socket{sock: sock}), do: Socket.send(sock, @noop)

  def send(message, %Socket{sock: sock, bolt_version: bolt_version}) do
    max_chunk_size = Integer.pow(2, @chunk_size)

    message
    |> Encoder.encode(bolt_version)
    |> Stream.unfold(fn
      <<>> ->
        nil

      # full chunk
      <<data::binary-size(max_chunk_size), rest::binary>> ->
        {send_chunk(data, max_chunk_size, sock), rest}

      # small chunk
      <<rest::binary>> ->
        {send_chunk(rest, byte_size(rest), sock), <<>>}
    end)
    |> Enum.reduce_while(:ok, fn
      :ok, response -> {:cont, response}
      err, _ -> {:halt, err}
    end)
  end

  def read(%Socket{} = socket) do
    {:ok, read_chunk([], socket)}
  rescue
    error -> {:error, error}
  end

  defp send_chunk(data, data_size, sock) do
    chunk = <<data_size::@chunk_size, data::binary, @noop>>
    Socket.send(sock, chunk)
  end

  defp read_chunk(
         data_parts,
         %Socket{sock: sock, bolt_version: bolt_version} = socket
       ) do
    with(
      {:ok, <<chunk_size::@chunk_size>>} when chunk_size > 0 <- Socket.recv(sock, 2),
      {:ok, data} when data != @noop <- Socket.recv(sock, chunk_size)
    ) do
      read_chunk([data | data_parts], socket)
    else
      {:ok, @noop} ->
        data_parts
        |> Enum.reverse()
        |> IO.iodata_to_binary()
        |> Decoder.decode(bolt_version)
        |> Enum.take(1)
        |> hd()

      {:error, error} ->
        # simplest way to bubble exception from recursive function
        raise DBConnection.ConnectionError.exception(inspect(error))
    end
  end

  ## Connection helpers

  defp checkout_or_transaction(fun, pool, opts, callback) do
    callback = fn conn ->
      previous_conn = put_conn(pool, conn)

      try do
        callback.(conn)
      after
        reset_conn(pool, previous_conn)
      end
    end

    apply(DBConnection, fun, [get_conn_or_pool(pool), callback, opts])
  end

  defp get_conn_or_pool(pool) do
    Process.get(key(pool), pool)
  end

  defp get_conn(pool) do
    Process.get(key(pool))
  end

  defp put_conn(pool, conn) do
    Process.put(key(pool), conn)
  end

  defp reset_conn(pool, conn) do
    if conn do
      put_conn(pool, conn)
    else
      Process.delete(key(pool))
    end
  end

  defp key(pool), do: {__MODULE__, pool}
end
