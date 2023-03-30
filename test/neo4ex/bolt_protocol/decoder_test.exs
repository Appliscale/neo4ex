defmodule Neo4Ex.BoltProtocol.DecoderTest do
  use ExUnit.Case

  alias Neo4Ex.BoltProtocol.Structure.Graph.Relationship
  alias Neo4Ex.BoltProtocol.Structure.Graph.Node
  alias Neo4Ex.BoltProtocol.Structure.Graph.Legacy.DateTimeZoneId

  alias Neo4Ex.BoltProtocol.Structure.Message.Request.Route

  alias Neo4Ex.BoltProtocol.Decoder

  describe "decode/2" do
    test "handles decoding of Node structures" do
      assert [%Node{id: 1}] ==
               <<0xB3, 0x4E, 1, 0x90, 0xA0>>
               |> Decoder.decode("4.0.0")
               |> Enum.to_list()
    end

    test "handles decoding of Relationship structures" do
      assert [%Relationship{id: 1}] ==
               <<0xB5, 0x52, 1, 0xC0, 0xC0, 0x80, 0xA0>>
               |> Decoder.decode("4.0.0")
               |> Enum.to_list()
    end

    test "handles decoding of built-in structures" do
      assert [~D[2010-04-17]] ==
               <<0xB1, 0x44, 0xC9, 14_716::16>>
               |> Decoder.decode("4.0.0")
               |> Enum.to_list()
    end

    test "handles decoding of legacy structures" do
      assert [%DateTimeZoneId{}] ==
               <<0xB3, 0x66, 0, 0, 0x80>>
               |> Decoder.decode("4.0.0")
               |> Enum.to_list()

      assert [%Route{}] ==
               <<0xB3, 0x66, 0xA0, 0x90, 0x80>>
               |> Decoder.decode("4.3.0")
               |> Enum.to_list()
    end
  end
end
