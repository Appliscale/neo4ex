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
    test "sends message", %{socket: socket} do
      message = %Run{query: "message"}
      encoded_message = Encoder.encode(message, "0.0.0")
      message_size = byte_size(encoded_message)

      expect(SocketMock, :send, fn _,
                                   <<^message_size::16,
                                     ^encoded_message::binary-size(message_size), 0::16>> ->
        :ok
      end)

      Connector.send(message, socket)
    end
  end
end
