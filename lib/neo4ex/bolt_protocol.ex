defmodule Neo4ex.BoltProtocol do
  @moduledoc """
  Bolt is an application protocol for the execution of database queries via a database query language, such as Cypher.
  More info: https://neo4j.com/docs/bolt/current/bolt
  """
  use DBConnection

  require Logger

  alias Neo4ex.BoltProtocol.Structure.Message.Request.Discard
  alias Neo4ex.Cypher
  alias Neo4ex.Connector
  alias Neo4ex.Connector.Socket

  alias Neo4ex.BoltProtocol.Structure.Message.Extra
  alias Neo4ex.BoltProtocol.Structure.Message.Detail.Record

  alias Neo4ex.BoltProtocol.Structure.Message.Request.{
    Hello,
    Logon,
    Begin,
    Commit,
    Rollback,
    Run,
    Pull,
    Goodbye
  }

  alias Neo4ex.BoltProtocol.Structure.Message.Summary.{Success, Failure}

  @user_agent "Neo4ex/#{Application.spec(:neo4ex, :vsn)}"

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
    with(:ok <- Connector.send(%Goodbye{}, socket)) do
      Socket.close(sock)
    end
  end

  @impl true
  def checkout(state) do
    {:ok, state}
  end

  @impl true
  def ping(%Socket{bolt_version: bolt_version} = state) do
    if Version.match?(bolt_version, ">= 4.1.0") do
      # fixme: this is breaking the connection, but the documentation says it can be used
      # Connector.send_noop(state)
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
      {:ok, %Failure{metadata: %{"message" => failure}}} -> {:disconnect, failure, socket}
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
      {:ok, %Failure{metadata: %{"message" => failure}}} -> {:disconnect, failure, socket}
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
      {:ok, %Failure{metadata: %{"message" => failure}}} -> {:disconnect, failure, socket}
      {:error, error} -> {:disconnect, error, socket}
    end
  end

  @impl true
  def handle_prepare(query, _opts, state) do
    # TODO: provide hints for the query
    {:ok, query, state}
  end

  @impl true
  def handle_close(query, _opts, state) do
    {:ok, query, state}
  end

  @impl true
  def handle_execute(query, params, opts, %Socket{} = socket) do
    case handle_declare(query, params, opts, socket) do
      {:ok, q, cursor, sckt} ->
        result =
          Stream.cycle([0])
          |> Stream.transform(q, stream_transform(cursor, opts, sckt))
          |> Enum.to_list()

        {:ok, q, result, sckt}

      other ->
        other
    end
  rescue
    ex -> {:error, ex, socket}
  end

  @impl true
  def handle_declare(
        %Cypher.Query{query: cypher_query, params: params, opts: opts} = query,
        _params,
        _opts,
        socket
      ) do
    message = %Run{
      query: cypher_query,
      parameters: params,
      extra: %Extra.Begin{mode: opts[:mode] || "w"}
    }

    with(
      :ok <- Connector.send(message, socket),
      {:ok, %Success{} = success} <- Connector.read(socket),
      # initialize data stream
      pull_message <- %Pull{extra: %Extra.Pull{n: -1}},
      :ok <- Connector.send(pull_message, socket)
    ) do
      {:ok, query, success, %{socket | streaming: true}}
    else
      {:ok, %Failure{} = failure} -> {:error, failure, socket}
      {:error, error} -> {:disconnect, error, socket}
    end
  end

  @impl true
  def handle_fetch(_query, _cursor, _opts, socket) do
    case Connector.read(socket) do
      {:ok, %Record{data: data}} -> {:cont, data, socket}
      {:ok, %Success{}} -> {:halt, nil, %{socket | streaming: false}}
      {:ok, %Failure{metadata: %{"message" => failure}}} -> {:error, failure, socket}
      {:error, exception} -> {:error, exception, socket}
    end
  end

  @impl true
  def handle_deallocate(_query, _cursor, _opts, %{streaming: false} = state) do
    # nothing to do here because we exhausted the stream
    {:ok, nil, state}
  end

  def handle_deallocate(_query, _cursor, _opts, socket) do
    # make sure we discard any unconsumed data
    message = %Discard{extra: %Extra.Pull{n: -1}}

    with(
      :ok <- Connector.send(message, socket),
      {:ok, %Success{} = result} <- Connector.read(socket)
    ) do
      {:ok, result, socket}
    else
      {:ok, %Failure{} = failure} -> {:error, failure, socket}
      {:error, error} -> {:disconnect, error, socket}
    end
  end

  @impl true
  def handle_status(_opts, state) do
    # there is no documented way of reading connection state, although it could be useful if possible
    {:idle, state}
  end

  defp handshake(sock, opts) do
    # we must always send 4 options for version negotiation
    supported_versions =
      opts
      |> Keyword.get(:versions, [])
      |> Enum.concat([0.0, 0.0, 0.0, 0.0])
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

  defp stream_transform(cursor, opts, sckt) do
    fn _, q ->
      case handle_fetch(q, cursor, opts, sckt) do
        {:cont, data, _} -> {[data], q}
        {:halt, _, _} -> {:halt, q}
        {:error, exception, _} -> raise exception
      end
    end
  end
end
