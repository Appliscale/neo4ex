defmodule Neo4ex.BoltProtocolTest do
  use ExUnit.Case, async: true

  import Mox
  import Neo4ex.Neo4jConnection

  alias Neo4ex.BoltProtocol.Structure.Message.Extra
  alias Neo4ex.BoltProtocol.Structure.Message.Request.Logon
  alias Neo4ex.BoltProtocol.Structure.Message.Request.Hello
  alias Neo4ex.BoltProtocol.Structure.Message.Request.Rollback
  alias Neo4ex.BoltProtocol.Structure.Message.Request.Commit
  alias Neo4ex.BoltProtocol.Structure.Message.Request.Begin
  alias Neo4ex.BoltProtocol.Structure.Message.Summary.Failure
  alias Neo4ex.Cypher
  alias Neo4ex.Connector.{Socket, SocketMock}
  alias Neo4ex.BoltProtocol
  alias Neo4ex.BoltProtocol.Encoder
  alias Neo4ex.BoltProtocol.Structure.Message.Request.Goodbye
  alias Neo4ex.BoltProtocol.Structure.Message.Summary.Success
  alias Neo4ex.BoltProtocol.Structure.Message.Detail.Record

  setup :verify_on_exit!

  setup do
    query = %Cypher.Query{query: "testing...123"}
    # fake socket
    %{socket: %Socket{bolt_version: Version.parse!("4.3.0")}, query: query}
  end

  describe "connect/1" do
    test "properly negotiates version" do
      success_message = %Success{}
      encoded_success_message = Encoder.encode(success_message, "4.0.0")

      # two versions, 4.0.0 and 0.0.0 x 3 (client always sends 4 versions)
      handshake = <<0x60, 0x60, 0xB0, 0x17, 0::8, 0::8, 0::8, 4::8, 0::96>>

      hello = generate_message_chunk(%Hello{extra: %Extra.Hello{scheme: "none"}}, "4.0.0")

      SocketMock
      |> expect(:connect, fn ~c"noop", 7687, [:binary, {:active, false}] -> {:ok, nil} end)
      |> expect(:send, fn _, ^handshake -> :ok end)
      |> expect(:recv, fn _, 4 -> {:ok, <<0::16, 0::8, 4::8>>} end)
      |> expect(:send, fn _, ^hello -> :ok end)
      |> expect_message(encoded_success_message)

      assert {:ok, %Socket{bolt_version: %Version{major: 4, minor: 0, patch: 0}}} ==
               BoltProtocol.connect(hostname: "noop", versions: ["4.0.0"])

      encoded_success_message = Encoder.encode(success_message, "5.3.0")

      # two versions, 5.3.0 and 0.0.0 x 3 (client always sends 4 versions)
      handshake = <<0x60, 0x60, 0xB0, 0x17, 0::8, 0::8, 3::8, 5::8, 0::96>>

      hello = generate_message_chunk(%Hello{}, "5.3.0")

      logon =
        generate_message_chunk(
          %Logon{auth: %Extra.Logon{scheme: "bearer", credentials: "abc"}},
          "5.3.0"
        )

      SocketMock
      |> expect(:connect, fn ~c"noop", 7687, [:binary, {:active, false}] -> {:ok, nil} end)
      |> expect(:send, fn _, ^handshake -> :ok end)
      |> expect(:recv, fn _, 4 -> {:ok, <<0::16, 3::8, 5::8>>} end)
      |> expect(:send, fn _, ^hello -> :ok end)
      |> expect_message(encoded_success_message)
      |> expect(:send, fn _, ^logon -> :ok end)
      |> expect_message(encoded_success_message)

      assert {:ok, %Socket{bolt_version: %Version{major: 5, minor: 3, patch: 0}}} ==
               BoltProtocol.connect(hostname: "noop", versions: ["5.3.0"], credentials: "abc")
    end

    test "gracefully handles failures" do
      message = %Failure{metadata: %{"message" => "failure"}}
      encoded_failure_message = Encoder.encode(message, "5.3.0")

      # two versions, 5.3.0 and 0.0.0 x 3 (client always sends 4 versions)
      handshake = <<0x60, 0x60, 0xB0, 0x17, 0::8, 0::8, 3::8, 5::8, 0::96>>

      hello = generate_message_chunk(%Hello{}, "5.3.0")

      SocketMock
      |> expect(:connect, fn ~c"noop", 7687, [:binary, {:active, false}] -> {:ok, nil} end)
      |> expect(:send, fn _, ^handshake -> :ok end)
      |> expect(:recv, fn _, 4 -> {:ok, <<0::16, 3::8, 5::8>>} end)
      |> expect(:send, fn _, ^hello -> :ok end)
      |> expect_message(encoded_failure_message)

      assert {:error, "failure"} == BoltProtocol.connect(hostname: "noop", versions: ["5.3.0"])
    end
  end

  describe "disconnect/2" do
    test "sends Goodbye message", %{socket: socket} do
      chunk = generate_message_chunk(%Goodbye{})

      SocketMock
      |> expect(:send, fn _, ^chunk -> :ok end)
      |> expect(:close, fn nil -> :ok end)

      BoltProtocol.disconnect(nil, socket)
    end
  end

  describe "handle_begin/2" do
    test "disconnects when transaction couldn't be started", %{socket: socket} do
      message = %Failure{metadata: %{"message" => "failure"}}
      encoded_failure_message = Encoder.encode(message, "4.0.0")

      chunk = generate_message_chunk(%Begin{})

      SocketMock
      |> expect(:send, 2, fn _, ^chunk -> :ok end)
      |> expect_message(encoded_failure_message)
      |> expect(:recv, fn _, _ -> {:error, "error"} end)

      assert {:disconnect, "failure", socket} == BoltProtocol.handle_begin([], socket)

      assert {:disconnect, DBConnection.ConnectionError.exception("\"error\""), socket} ==
               BoltProtocol.handle_begin([], socket)
    end
  end

  describe "handle_commit/2" do
    test "disconnects when transaction couldn't be started", %{socket: socket} do
      message = %Failure{metadata: %{"message" => "failure"}}
      encoded_failure_message = Encoder.encode(message, "4.0.0")

      chunk = generate_message_chunk(%Commit{})

      SocketMock
      |> expect(:send, 2, fn _, ^chunk -> :ok end)
      |> expect_message(encoded_failure_message)
      |> expect(:recv, fn _, _ -> {:error, "error"} end)

      assert {:disconnect, "failure", socket} == BoltProtocol.handle_commit([], socket)

      assert {:disconnect, DBConnection.ConnectionError.exception("\"error\""), socket} ==
               BoltProtocol.handle_commit([], socket)
    end
  end

  describe "handle_rollback/2" do
    test "disconnects when transaction couldn't be rolled back", %{socket: socket} do
      message = %Failure{metadata: %{"message" => "failure"}}
      encoded_failure_message = Encoder.encode(message, "4.0.0")

      chunk = generate_message_chunk(%Rollback{})

      SocketMock
      |> expect(:send, 2, fn _, ^chunk -> :ok end)
      |> expect_message(encoded_failure_message)
      |> expect(:recv, fn _, _ -> {:error, "error"} end)

      assert {:disconnect, "failure", socket} == BoltProtocol.handle_rollback([], socket)

      assert {:disconnect, DBConnection.ConnectionError.exception("\"error\""), socket} ==
               BoltProtocol.handle_rollback([], socket)
    end
  end

  describe "handle_execute/4" do
    test "returns data from stream", %{socket: socket, query: query} do
      message = %Record{data: ["message"]}
      encoded_message = Encoder.encode(message, "4.0.0")
      success_message = %Success{metadata: %{"t_first" => 1}}
      encoded_success_message = Encoder.encode(success_message, "4.0.0")

      SocketMock
      # query
      |> expect(:send, fn _, _ -> :ok end)
      # pull results
      |> expect(:send, fn _, _ -> :ok end)
      # summary message
      |> expect_message(encoded_success_message)
      # detail message
      |> expect_message(encoded_message)
      # summary message
      |> expect_message(encoded_success_message)

      assert {:ok, query, [["message"], %Success{metadata: %{"t_first" => 1}}], socket} ==
               BoltProtocol.handle_execute(query, %{}, [], socket)
    end

    test "raises error if stream gets interrupted", %{socket: socket, query: query} do
      message = %Record{data: ["message"]}
      encoded_message = Encoder.encode(message, "4.0.0")
      success_message = %Success{metadata: %{"t_first" => 1}}
      encoded_success_message = Encoder.encode(success_message, "4.0.0")

      SocketMock
      # query
      |> expect(:send, fn _, _ -> :ok end)
      # pull results
      |> expect(:send, fn _, _ -> :ok end)
      # summary message
      |> expect_message(encoded_success_message)
      # detail message
      |> expect_message(encoded_message)
      # summary message
      |> expect(:recv, fn _, 2 -> {:error, :closed} end)
      # deallocate (we haven't consumed whole stream)
      |> expect(:send, fn _, _ -> :ok end)
      |> expect_message(encoded_success_message)

      assert_raise DBConnection.ConnectionError, fn ->
        BoltProtocol.handle_execute(query, %{}, [], socket)
      end
    end

    test "throws error if stream returns failure", %{socket: socket, query: query} do
      message = %Failure{metadata: %{"message" => "failure"}}
      encoded_failure_message = Encoder.encode(message, "4.0.0")

      SocketMock
      # query
      |> expect(:send, fn _, _ -> :ok end)
      # summary message
      |> expect_message(encoded_failure_message)

      assert_raise DBConnection.ConnectionError, fn ->
        BoltProtocol.handle_execute(query, %{}, [], socket)
      end
    end
  end
end
