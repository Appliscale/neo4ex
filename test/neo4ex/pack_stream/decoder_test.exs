defmodule Neo4Ex.PackStream.DecoderTest do
  use ExUnit.Case, async: true

  alias Neo4Ex.PackStream.Decoder

  describe "read_chunk/1" do
    test "decodes basic structures" do
      assert {nil, ""} == Decoder.decode(<<0xC0>>)
      assert {false, ""} == Decoder.decode(<<0xC2>>)
      assert {[], ""} == Decoder.decode(<<0x90>>)
      assert {123, ""} == Decoder.decode(<<0x7B>>)
      assert {2.0, ""} == Decoder.decode(<<0xC1, 0x40, 0x0::56>>)

      # Lists and maps work a bit different
      assert {["abba", "baba"], ""} ==
               <<0x92, 0x84, "abba", 0x84, "baba">>
               |> Decoder.decode()
               |> then(fn {list, bin} ->
                 Enum.map_reduce(list, bin, fn _, d -> Decoder.decode(d) end)
               end)

      assert {%{"a" => "abba", "b" => "baba"}, ""} ==
               <<0xA2, 0x81, "a", 0x84, "abba", 0x81, "b", 0x84, "baba">>
               |> Decoder.decode()
               |> then(fn {%{size: map_size}, bin} ->
                 {data, rest} =
                   Enum.map_reduce(1..map_size, bin, fn _, d ->
                     {key, d} = Decoder.decode(d)
                     {value, d} = Decoder.decode(d)
                     {{key, value}, d}
                   end)

                 {Enum.into(data, %{}), rest}
               end)
    end
  end
end
