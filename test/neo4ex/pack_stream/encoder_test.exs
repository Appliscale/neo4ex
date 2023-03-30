defmodule Neo4Ex.PackStream.EncoderTest do
  use ExUnit.Case

  alias Neo4Ex.PackStream.Encoder

  describe "encode/1" do
    test "returns valid binary representation of random small Integers" do
      assert <<0xF0>> == Encoder.encode(-16)
      assert <<0xF1>> == Encoder.encode(-15)
      assert <<0x0>> == Encoder.encode(0)
      assert <<0x02>> == Encoder.encode(2)
      assert <<0x20>> == Encoder.encode(32)
      assert <<0x7F>> == Encoder.encode(127)
    end

    test "returns valid binary representation of one byte Integers" do
      -128..-17
      |> Enum.each(fn num -> assert <<0xC8, num>> == Encoder.encode(num) end)
    end

    test "returns valid binary representation of two byte Integers" do
      128..32_767
      |> Enum.each(fn num -> assert <<0xC9, num::16>> == Encoder.encode(num) end)

      -32_768..-129
      |> Enum.each(fn num -> assert <<0xC9, num::16>> == Encoder.encode(num) end)
    end

    test "returns valid binary representation of four byte Integers" do
      32_768..2_147_483_647//32_768
      |> Enum.each(fn num -> assert <<0xCA, num::32>> == Encoder.encode(num) end)

      -2_147_483_648..-32_769//32_768
      |> Enum.each(fn num -> assert <<0xCA, num::32>> == Encoder.encode(num) end)
    end

    test "returns valid binary representation of random eight byte Integers" do
      assert <<0xCB, -36_854_775_808::64>> == Encoder.encode(-36_854_775_808)
      assert <<0xCB, 1_232_147_483_648::64>> == Encoder.encode(1_232_147_483_648)
      assert <<0xCB, 2_555_555_332_346_456::64>> == Encoder.encode(2_555_555_332_346_456)

      assert <<0xCB, 0x80, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0>> ==
               Encoder.encode(-9_223_372_036_854_775_808)

      assert <<0xCB, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF>> ==
               Encoder.encode(9_223_372_036_854_775_807)
    end

    test "returns valid binary representation of Floats" do
      assert <<0xC1, 0x3F, 0xF3, 0xAE, 0x14, 0x7A, 0xE1, 0x47, 0xAE>> == Encoder.encode(1.23)
      assert <<0xC1, 0x40, 0x0::56>> == Encoder.encode(2.0)
    end

    test "returns valid binary representation of Strings" do
      rand = fn -> Enum.random(65..120) end
      long_str = Stream.repeatedly(rand) |> Enum.take(512) |> to_string()
      assert <<0x85, "Hello">> == Encoder.encode("Hello")
      # make sure emojis are properly coutned by bytes
      assert <<0x8E, "Hello 👍🏾">> == Encoder.encode("Hello 👍🏾")
      assert <<0xD0, 0x21, "Hello 👩‍👩‍👦 👍🏾">> == Encoder.encode("Hello 👩‍👩‍👦 👍🏾")
      assert <<0xD1, 512::16, long_str::binary>> == Encoder.encode(long_str)
    end

    test "returns valid binary representation of Atoms" do
      assert <<0x85, "hello">> == Encoder.encode(:hello)
    end

    test "returns valid binary representation of Binaries" do
      rand = fn -> Enum.random(0..120) end
      long_str = Stream.repeatedly(rand) |> Enum.take(512) |> to_string()
      assert <<0xCD, 512::16, long_str::binary>> == Encoder.encode(long_str)
    end

    test "returns valid binary header of Lists" do
      assert <<0x90>> == Encoder.encode([])
      assert <<0x93>> == Encoder.encode([1, "a", 2.0])
      assert <<0xD4, 20>> == 1..20 |> Enum.to_list() |> Encoder.encode()
    end

    test "returns valid binary header of Maps" do
      assert <<0xA3>> == Encoder.encode(%{a: 1, b: "a", c: 2.0})
    end

    test "raises error when trying to encode Tuple" do
      assert_raise(Protocol.UndefinedError, fn -> Encoder.encode({:a, :b}) end)
    end
  end
end
