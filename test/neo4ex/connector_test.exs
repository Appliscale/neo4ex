defmodule Neo4Ex.ConnectorTest do
  use ExUnit.Case, async: true

  import Mox

  alias Neo4Ex.BoltProtocol.Structure.Message.Request.Run
  alias Neo4Ex.BoltProtocol.Encoder

  alias Neo4Ex.Connector
  alias Neo4Ex.Connector.SocketMock

  setup :verify_on_exit!

  setup do
    # fake socket
    %{socket: %Connector.Socket{}}
  end

  describe "send_noop/1" do
    test "sends zeros", %{socket: socket} do
      expect(SocketMock, :send, fn _, <<0::16>> -> :ok end)
      Connector.send_noop(socket)
    end
  end

  describe "send/2" do
    test "sends message to socket", %{socket: socket} do
      message = %Run{query: "message"}
      encoded_message = Encoder.encode(message, "0.0.0")
      message_size = byte_size(encoded_message)

      expect(SocketMock, :send, fn _,
                                   <<^message_size::16,
                                     ^encoded_message::binary-size(message_size), 0::16>> ->
        :ok
      end)

      assert :ok == Connector.send(message, socket)
    end

    test "returns error on send failure", %{socket: socket} do
      message = %Run{query: "message"}

      expect(SocketMock, :send, fn _, _ -> {:error, :closed} end)

      assert {:error, :closed} == Connector.send(message, socket)
    end
  end

  describe "read/1" do
    test "reads from socket", %{socket: socket} do
      SocketMock
      |> expect(:recv, fn _, 2 -> {:ok, <<5::16>>} end)
      |> expect(:recv, fn _, 5 -> {:ok, <<0x84>> <> "data"} end)
      |> expect(:recv, fn _, 2 -> {:ok, <<0::16>>} end)

      assert {:ok, "data"} == Connector.read(socket)
    end

    test "returns error on read failure", %{socket: socket} do
      SocketMock
      |> expect(:recv, fn _, 2 -> {:error, :closed} end)
      |> expect(:recv, fn _, 2 -> {:ok, <<5::16>>} end)
      |> expect(:recv, fn _, 5 -> {:ok, <<0x84>> <> "data"} end)
      |> expect(:recv, fn _, 2 -> {:error, :closed} end)

      # this one fails on first request
      assert {:error, DBConnection.ConnectionError.exception(":closed")} == Connector.read(socket)

      # this one fails just before chunk ends
      assert {:error, DBConnection.ConnectionError.exception(":closed")} == Connector.read(socket)
    end
  end
end
