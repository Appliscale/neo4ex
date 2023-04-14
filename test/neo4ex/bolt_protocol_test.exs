defmodule Neo4ex.BoltProtocolTest do
  use ExUnit.Case, async: true

  import Mox
  import Neo4ex.Neo4jConnection

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
    %{socket: %Socket{bolt_version: "4.3.0"}, query: query}
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

      assert {:ok, query, [["message"]], socket} ==
               BoltProtocol.handle_execute(query, %{}, [], socket)
    end

    test "returns error if stream gets interrupted", %{socket: socket, query: query} do
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

      assert {:error, DBConnection.ConnectionError.exception(inspect(:closed)), socket} ==
               BoltProtocol.handle_execute(query, %{}, [], socket)
    end
  end
end
