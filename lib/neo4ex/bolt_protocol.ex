defmodule Neo4Ex.BoltProtocol do
  @moduledoc """
  Bolt is an application protocol for the execution of database queries via a database query language, such as Cypher.
  More info: https://neo4j.com/docs/bolt/current/bolt
  """
  use DBConnection

  require Logger

  alias Neo4Ex.Cypher
  alias Neo4Ex.Connector
  alias Neo4Ex.Connector.Socket

  alias Neo4Ex.BoltProtocol.Structure.Message.Extra

  alias Neo4Ex.BoltProtocol.Structure.Message.Request.{
    Hello,
    Logon,
    Begin,
    Commit,
    Rollback,
    Run,
    Goodbye
  }

  alias Neo4Ex.BoltProtocol.Structure.Message.Summary.{Success, Failure}

  @user_agent "Neo4Ex/#{Application.spec(:neo4ex, :vsn)}"

  @impl true
  def connect(opts) do
    hostname = Keyword.get(opts, :hostname)
    port = Keyword.get(opts, :port, 7687)

    sock_opts = [:binary, active: false]

    with {:ok, sock} <- Socket.connect(hostname, port, sock_opts),
         {:ok, socket} <- handshake(sock, opts),
         :ok <- hello(socket, opts) do
      {:ok, socket}
    else
      other -> other
    end
  end

  @impl true
  def disconnect(_exception, %Socket{sock: sock} = socket) do
    with(
      :ok <- Connector.send(%Goodbye{}, socket),
      :ok <- Socket.close(sock)
    ) do
      :ok
    end
  end

  @impl true
  def checkout(state) do
    {:ok, state}
  end

  @impl true
  def ping(%Socket{bolt_version: bolt_version} = state) do
    if Version.match?(bolt_version, ">= 4.1.0") do
      # since version 4.1 there is keep alive behaviour
      Connector.send_noop(state)
    end

    {:ok, state}
  end

  @impl true
  def handle_begin(_opts, socket) do
    message = %Begin{extra: %Extra.Begin{}}

    with(
      :ok <- Connector.send(message, socket),
      {:ok, %Success{} = response} <- Connector.read(socket)
    ) do
      {:ok, response, socket}
    else
      {:ok, %Failure{} = failure} -> {failure, socket}
      {:error, error} -> {:disconnect, error, socket}
    end
  end

  @impl true
  def handle_commit(_opts, socket) do
    with(
      :ok <- Connector.send(%Commit{}, socket),
      {:ok, %Success{} = response} <- Connector.read(socket)
    ) do
      {:ok, response, socket}
    else
      {:ok, %Failure{} = failure} -> {failure, socket}
      {:error, error} -> {:disconnect, error, socket}
    end
  end

  @impl true
  def handle_rollback(_opts, socket) do
    with(
      :ok <- Connector.send(%Rollback{}, socket),
      {:ok, %Success{} = response} <- Connector.read(socket)
    ) do
      {:ok, response, socket}
    else
      {:ok, %Failure{} = failure} -> {failure, socket}
      {:error, error} -> {:disconnect, error, socket}
    end
  end

  @impl true
  def handle_close(_, _, state) do
    {:ok, :ok, state}
  end

  @impl true
  def handle_prepare(query, _opts, state) do
    {:ok, query, state}
  end

  @impl true
  def handle_execute(
        %Cypher.Query{query: cypher_query, params: params, opts: opts} = query,
        _,
        _,
        %Socket{} = socket
      ) do
    message = %Run{
      query: cypher_query,
      parameters: params,
      extra: %Extra.Begin{mode: opts[:mode] || "w"}
    }

    with(
      :ok <- Connector.send(message, socket),
      {:ok, %Success{metadata: %{"t_first" => t_first}}} <- Connector.read(socket)
    ) do
      result_stream =
        t_first
        |> Stream.timer()
        |> Stream.flat_map(fn _ -> Connector.read_stream(socket) end)

      {:ok, query, result_stream, socket}
    else
      {:ok, %Failure{} = failure} -> {:error, failure, socket}
      {:error, error} -> {:disconnect, error, socket}
    end
  end

  defp handshake(sock, opts) do
    # we must always send 4 options for version negotiation
    supported_versions =
      opts
      |> Keyword.get(:versions, [0, 0, 0, 0])
      |> Enum.take(4)
      |> Enum.map(fn float ->
        [major, minor] =
          float |> Float.to_string() |> String.split(".") |> Enum.map(&String.to_integer/1)

        <<0::16, minor, major>>
      end)
      |> IO.iodata_to_binary()

    handshake_header = <<0x60, 0x60, 0xB0, 0x17>>
    Socket.send(sock, handshake_header <> supported_versions)

    with(
      {:ok, <<0::16, minor, major>>} <- Socket.recv(sock, 4),
      {:ok, bolt_version} <- Version.parse("#{major}.#{minor}.0")
    ) do
      socket = %Socket{
        sock: sock,
        bolt_version: bolt_version
      }

      {:ok, socket}
    else
      other -> {:error, other}
    end
  end

  defp hello(%Socket{bolt_version: bolt_version} = socket, opts) do
    principal = Keyword.get(opts, :principal)
    credentials = Keyword.get(opts, :credentials)

    scheme =
      cond do
        !principal and !credentials -> "none"
        !principal and credentials -> "bearer"
        true -> "basic"
      end

    if Version.match?(bolt_version, ">= 5.1.0") do
      hello = %Hello{extra: %Extra.Hello{user_agent: @user_agent}}

      logon = %Logon{
        scheme: scheme,
        principal: principal,
        credentials: credentials
      }

      with(
        :ok <- Connector.send(hello, socket),
        {:ok, %Success{}} <- Connector.read(socket),
        :ok <- Connector.send(logon, socket),
        {:ok, %Success{}} <- Connector.read(socket)
      ) do
        :ok
      else
        other -> other
      end
    else
      message = %Hello{
        extra: %Extra.Hello{
          user_agent: @user_agent,
          scheme: scheme,
          principal: principal,
          credentials: credentials
        }
      }

      with(
        :ok <- Connector.send(message, socket),
        {:ok, %Success{}} <- Connector.read(socket)
      ) do
        :ok
      else
        other -> other
      end
    end
  end
end
