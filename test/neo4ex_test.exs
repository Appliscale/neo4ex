defmodule Neo4exTest do
  use ExUnit.Case

  import Mox
  import Neo4ex.Neo4jConnection

  alias Neo4ex.BoltProtocol.Structure.Message.Request.Begin
  alias Neo4ex.BoltProtocol.Structure.Message.Request.Commit
  alias Neo4ex.BoltProtocol.Structure.Message.Request.Rollback
  alias Neo4ex.Cypher.Query
  alias Neo4ex.Connector.SocketMock
  alias Neo4ex.BoltProtocol.Encoder
  alias Neo4ex.BoltProtocol.Structure.Message.Summary.Success
  alias Neo4ex.BoltProtocol.Structure.Message.Detail.Record
  # make it last alias so it doesn't break the ones above
  alias Neo4ex.Neo4jConnection, as: Neo4ex

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

    {:ok, _} = Neo4ex.start_link([])

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

      assert {:ok, q,
              [["hello", "goodbye"], ["hello", "goodbye"], %Success{metadata: %{"t_first" => 1}}]} ==
               Neo4ex.run(q)
    end

    test "calls explain on query before sending when debug enabled" do
      message = %Record{data: ["hello", "goodbye"]}
      encoded_message = Encoder.encode(message, "4.0.0")
      success_message = %Success{metadata: %{"t_first" => 1}}
      encoded_success_message = Encoder.encode(success_message, "4.0.0")

      SocketMock
      # explain
      |> expect(:send, fn _, _ -> :ok end)
      |> expect_message(encoded_success_message)
      |> expect(:send, fn _, _ -> :ok end)
      |> expect_message(encoded_success_message)
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

      assert {:ok, q,
              [["hello", "goodbye"], ["hello", "goodbye"], %Success{metadata: %{"t_first" => 1}}]} ==
               Neo4ex.run(q, debug: true)
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

      stream = Neo4ex.stream(%Query{})

      Neo4ex.transaction(fn ->
        assert ["hello", "hello", "goodbye"] ==
                 Enum.reduce_while(stream, [], fn x, acc ->
                   # this will stop stream in the middle
                   if acc == x, do: {:halt, [hd(x) | acc]}, else: {:cont, acc ++ x}
                 end)
      end)
    end
  end

  describe "transaction/0" do
    test "sends commit on success" do
      message = %Success{}
      encoded_success_message = Encoder.encode(message, "4.0.0")

      begin = generate_message_chunk(%Begin{})
      chunk = generate_message_chunk(%Commit{})

      SocketMock
      |> expect(:send, fn _, ^begin -> :ok end)
      |> expect_message(encoded_success_message)
      |> expect(:send, fn _, ^chunk -> :ok end)
      |> expect_message(encoded_success_message)

      Neo4ex.transaction(fn ->
        :ok
      end)
    end

    test "sends rollback on error" do
      message = %Success{}
      encoded_success_message = Encoder.encode(message, "4.0.0")

      begin = generate_message_chunk(%Begin{})
      chunk = generate_message_chunk(%Rollback{})

      SocketMock
      |> expect(:send, fn _, ^begin -> :ok end)
      |> expect_message(encoded_success_message)
      |> expect(:send, fn _, ^chunk -> :ok end)
      |> expect_message(encoded_success_message)

      assert {:error, :oops} =
               Neo4ex.transaction(fn conn ->
                 DBConnection.rollback(conn, :oops)
               end)
    end
  end
end
