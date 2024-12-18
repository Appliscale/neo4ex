defmodule Neo4ex.Neo4jConnection do
  @moduledoc false

  use Neo4ex.Connector,
    otp_app: :neo4ex

  import Mox

  alias Neo4ex.BoltProtocol.Encoder

  def generate_message_chunk(message, version \\ "4.0.0") do
    encoded_message = Encoder.encode(message, version)
    message_size = byte_size(encoded_message)
    <<message_size::16, encoded_message::binary, 0::16>>
  end

  def expect_message(mock, message) do
    mock
    |> expect(:recv, fn _, 2 -> {:ok, <<1::16>>} end)
    |> expect(:recv, fn _, 1 -> {:ok, message} end)
    |> expect(:recv, fn _, 2 -> {:ok, <<0::16>>} end)
  end
end
