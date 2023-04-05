defmodule Neo4ex.BoltProtocolTest do
  use ExUnit.Case, async: true

  import Mox

  alias Neo4ex.Cypher
  alias Neo4ex.Connector.{Socket, SocketMock}
  alias Neo4ex.BoltProtocol
  alias Neo4ex.BoltProtocol.Encoder
  alias Neo4ex.BoltProtocol.Structure.Message.Summary.Success
  alias Neo4ex.BoltProtocol.Structure.Message.Detail.Record

  setup :verify_on_exit!

  setup do
    query = %Cypher.Query{query: "testing...123"}
    # fake socket
    %{socket: %Socket{bolt_version: "4.3.0"}, query: query}
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
      |> expect(:recv, fn _, 2 -> {:ok, <<5::16>>} end)
      |> expect(:recv, fn _, _ -> {:ok, encoded_success_message} end)
      |> expect(:recv, fn _, 2 -> {:ok, <<0::16>>} end)
      # detail message
      |> expect(:recv, fn _, 2 -> {:ok, <<5::16>>} end)
      |> expect(:recv, fn _, _ -> {:ok, encoded_message} end)
      |> expect(:recv, fn _, 2 -> {:ok, <<0::16>>} end)
      # summary message
      |> expect(:recv, fn _, 2 -> {:ok, <<5::16>>} end)
      |> expect(:recv, fn _, _ -> {:ok, encoded_success_message} end)
      |> expect(:recv, fn _, 2 -> {:ok, <<0::16>>} end)

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
      |> expect(:recv, fn _, 2 -> {:ok, <<5::16>>} end)
      |> expect(:recv, fn _, _ -> {:ok, encoded_success_message} end)
      |> expect(:recv, fn _, 2 -> {:ok, <<0::16>>} end)
      # detail message
      |> expect(:recv, fn _, 2 -> {:ok, <<5::16>>} end)
      |> expect(:recv, fn _, _ -> {:ok, encoded_message} end)
      |> expect(:recv, fn _, 2 -> {:ok, <<0::16>>} end)
      # summary message
      |> expect(:recv, fn _, 2 -> {:error, :closed} end)

      assert {:error, DBConnection.ConnectionError.exception(inspect(:closed)), socket} ==
               BoltProtocol.handle_execute(query, %{}, [], socket)
    end
  end
end
