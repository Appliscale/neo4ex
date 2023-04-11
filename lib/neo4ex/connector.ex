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
  @supported_versions [4.3, 4.2, 4.1, 4.0]

  defmacro __using__(otp_app: app) do
    supported_versions = @supported_versions

    quote do
      use Supervisor

      @connector_opts Application.compile_env(unquote(app), __MODULE__, [])

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
      def run(%Cypher.Query{} = query) do
        case prepare_query(query) do
          {:ok, args} -> apply(DBConnection, :execute, args)
          other -> other
        end
      end

      @doc """
      Executes Cypher query on the database and returns results.
      This function uses reducer to read data from stream.
      Reducer may finish prematurely. In that case, remaining part of the stream will be thrown away.
      """
      def stream(%Cypher.Query{} = query, reducer) when is_function(reducer, 2) do
        with(
          {:ok, [conn | args]} <- prepare_query(query),
          {:ok, stream} <-
            DBConnection.transaction(conn, fn conn ->
              # we have to consume stream within transaction
              DBConnection
              |> apply(:stream, [conn | args])
              |> Stream.reject(&is_nil/1)
              |> Enum.reduce_while([], reducer)
            end)
        ) do
          stream
        end
      end

      def transaction(func) when is_function(func, 1) do
        conn = connection_pool!()
        DBConnection.transaction(conn, func)
      end

      defp prepare_query(query) do
        conn = connection_pool!()

        case DBConnection.prepare(conn, query) do
          {:ok, query} -> {:ok, [conn, query, []]}
          other -> other
        end
      end

      defp connection_pool!() do
        case Supervisor.which_children(__MODULE__) do
          [{_, conn, _, [DBConnection]} | _] -> conn
          [] -> raise "Please add #{__MODULE__} to application Supervision tree"
        end
      end
    end
  end

  def supported_versions(), do: @supported_versions

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
end
