defmodule Neo4Ex.Connector do
  @moduledoc """
  Module responsible for communication with the database engine
  """
  use Supervisor

  import Kernel, except: [send: 2]

  alias Neo4Ex.Connector.Socket

  alias Neo4Ex.BoltProtocol
  alias Neo4Ex.BoltProtocol.{Encoder, Decoder}

  # Chunk headers are 16-bit unsigned integers
  @chunk_size 16
  @noop <<0::size(@chunk_size)>>
  @supported_versions [4.3, 4.2, 4.1, 4.0]
  @connector_opts Application.compile_env(:neo4ex, Neo4Ex.Connector, [])

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
          {DBConnection, :start_link, [BoltProtocol, [{:versions, @supported_versions} | opts]]}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
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
