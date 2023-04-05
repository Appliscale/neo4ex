defmodule Neo4ExTest do
  use ExUnit.Case

  import Mox

  alias Neo4ex.Cypher.Query
  alias Neo4ex.Connector.SocketMock
  alias Neo4ex.BoltProtocol.Encoder
  alias Neo4ex.BoltProtocol.Structure.Message.Summary.Success
  alias Neo4ex.BoltProtocol.Structure.Message.Detail.Record

  setup :set_mox_from_context
  setup :verify_on_exit!

  setup do
    success_message = %Success{}
    encoded_success_message = Encoder.encode(success_message, "4.0.0")

    SocketMock
    |> expect(:connect, fn 'localhost', 7687, [:binary, {:active, false}] ->
      :gen_tcp.listen(0, [:binary])
    end)
    # handshake
    |> expect(:send, fn _, <<0x60, 0x60, 0xB0, 0x17>> <> _ -> :ok end)
    # wersion should be 4.0 to avoid PINGs introduced in 4.1
    |> expect(:recv, fn _, 4 -> {:ok, <<0::16, 0, 4>>} end)
    # hello
    |> expect(:send, fn _, _ -> :ok end)
    |> expect_message(encoded_success_message)

    {:ok, _} = Neo4ex.Connector.start_link([])

    :ok
  end

  describe "run/1" do
    test "runs single query" do
      message = %Record{data: ["hello", "goodbye"]}
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
      |> expect_message(encoded_message)
      # summary message
      |> expect_message(encoded_success_message)

      q = %Query{}
      assert {:ok, q, [["hello", "goodbye"], ["hello", "goodbye"]]} == Neo4ex.run(q)
    end
  end

  describe "stream/1" do
    test "returns iterable stream" do
      message = %Record{data: ["hello", "goodbye"]}
      encoded_message = Encoder.encode(message, "4.0.0")
      success_message = %Success{metadata: %{"t_first" => 1}}
      encoded_success_message = Encoder.encode(success_message, "4.0.0")

      SocketMock
      # begin transaction
      |> expect(:send, fn _, _ -> :ok end)
      |> expect_message(encoded_success_message)
      # query
      |> expect(:send, fn _, _ -> :ok end)
      # pull results
      |> expect(:send, fn _, _ -> :ok end)
      # summary message
      |> expect_message(encoded_success_message)
      # detail messages
      |> expect_message(encoded_message)
      |> expect_message(encoded_message)
      # no summary here because we're not consuming whole stream
      # discard message
      |> expect(:send, fn _, _ -> :ok end)
      # discard success message
      |> expect_message(encoded_success_message)
      # commit transaction
      |> expect(:send, fn _, _ -> :ok end)
      |> expect_message(encoded_success_message)

      q = %Query{}

      assert ["hello", "hello", "goodbye"] ==
               Neo4ex.stream(q, fn x, acc ->
                 # this will stop stream in the middle
                 if acc == x, do: {:halt, [hd(x) | acc]}, else: {:cont, acc ++ x}
               end)
    end
  end

  defp expect_message(mock, message) do
    mock
    |> expect(:recv, fn _, 2 -> {:ok, <<1::16>>} end)
    |> expect(:recv, fn _, 1 -> {:ok, message} end)
    |> expect(:recv, fn _, 2 -> {:ok, <<0::16>>} end)
  end
end
