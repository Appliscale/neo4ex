defmodule Neo4ex.BoltProtocol.EncoderTest do
  use ExUnit.Case, async: true

  alias Neo4ex.BoltProtocol.Structure.Graph.Relationship
  alias Neo4ex.BoltProtocol.Structure.Graph.Node
  alias Neo4ex.BoltProtocol.Structure.Graph.Legacy.DateTimeZoneId
  alias Neo4ex.BoltProtocol.Structure.Message.Request.{Hello, Route}
  alias Neo4ex.BoltProtocol.Structure.Message.Extra

  alias Neo4ex.BoltProtocol.Encoder
  alias Neo4ex.PackStream.Exceptions

  @version Mix.Project.config()[:version]

  describe "encode/2" do
    test "returns valid binary representation of Lists" do
      assert <<0x90>> == Encoder.encode([], "4.0.0")

      assert <<0x93, 1, 0x81, "a", 0xC1, 0x4::4, 0x0::60>> ==
               Encoder.encode([1, "a", 2.0], "4.0.0")

      assert <<0x92, 1, 0xB3, 0x4E, 0xC0, 0x90, 0xA0>> ==
               Encoder.encode([1, %Node{}], "4.0.0")

      assert <<0xD4, 20, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20>> ==
               1..20 |> Enum.to_list() |> Encoder.encode("4.0.0")
    end

    test "returns valid binary representation of Maps" do
      input = %{a: 1, b: "a", c: 2.0}

      # assert <<0xA3, 0x81, "a", 1, 0x81, "b", 0x81, "a", 0x81, "c", 0xC1, 0x4::4, 0x0::60>> ==
      #          Encoder.encode(%{a: 1, b: "a", c: 2.0}, "4.0.0")

      # Keys in maps aren't sorted in newest OTP. We have to pattern match on each possible sorting (assuming the same kinds of values will be kept together, so the order is string,string,float or float,string,string)
      case Encoder.encode(input, "4.0.0") do
        <<0xA3, 0x81, "a", 1, 0x81, "b", 0x81, "a", 0x81, "c", 0xC1, 0x4::4, 0x0::60>> ->
          :ok

        <<0xA3, 0x81, "b", 0x81, "a", 0x81, "a", 1, 0x81, "c", 0xC1, 0x4::4, 0x0::60>> ->
          :ok

        <<0xA3, 0x81, "c", 0xC1, 0x4::4, 0x0::60, 0x81, "a", 1, 0x81, "b", 0x81, "a">> ->
          :ok

        <<0xA3, 0x81, "c", 0xC1, 0x4::4, 0x0::60, 0x81, "b", 0x81, "a", 0x81, "a", 1>> ->
          :ok

        other ->
          flunk(
            "Got invalid encoding for map: #{inspect(input)}, the result was: #{inspect(other)}"
          )
      end
    end

    test "handles encoding of Node structures" do
      assert <<0xB::4, 3::4, 0x4E, 1, 0x90, 0xA0>> = Encoder.encode(%Node{id: 1}, "4.0.0")
    end

    test "handles encoding of Relationship structures" do
      assert <<0xB::4, 5::4, 0x52, 1, 0xC0, 0xC0, 0x80, 0xA0>> =
               Encoder.encode(%Relationship{id: 1}, "4.0.0")
    end

    test "handles encoding of built-in structures" do
      assert <<0xB1, 0x44, 0xC9, 14_716::16>> == Encoder.encode(~D[2010-04-17], "4.0.0")
    end

    test "handles encoding of legacy structures" do
      assert <<0xB3, 0x66, 0, 0, 0x80>> == Encoder.encode(%DateTimeZoneId{}, "4.0.0")
      assert_raise(Exceptions.EncodeError, fn -> Encoder.encode(%Route{}, "4.0.0") end)
      assert <<0xB3, 0x66, 0xA0, 0x90, 0x80>> == Encoder.encode(%Route{}, "4.3.0")
      assert_raise(Exceptions.EncodeError, fn -> Encoder.encode(%DateTimeZoneId{}, "4.3.0") end)
    end

    test "raises error when trying to encode Tuple" do
      assert_raise(Protocol.UndefinedError, fn -> Encoder.encode([{:a, "Hello"}, :b], "4.0.0") end)

      assert_raise(Protocol.UndefinedError, fn -> Encoder.encode([:c, {:a, "Hello"}], "4.0.0") end)
    end

    test "handles encoding of Hello messages" do
      app_version = "Neo4ex/#{@version}"
      user_agent_bytes = byte_size("user_agent")
      ua_bytes = byte_size(app_version)
      scheme_bytes = byte_size("scheme")
      none_bytes = byte_size("none")
      principal_bytes = byte_size("principal")
      credentials_bytes = byte_size("credentials")

      # even though Logon is a struct with prefdefined fields order, prior to 5.1 we're encoding it to the map so the keys will be sent according to map keys rules (compiler-defined, should be the same but can be random)
      assert <<0xB1, 0x01, 0xA4, 0x8::4, ^scheme_bytes::4, "scheme", 0x8::4, ^none_bytes::4,
               "none", 0x8::4, ^credentials_bytes::4, "credentials", 0x80, 0x8::4,
               ^user_agent_bytes::4, "user_agent", 0x8::4, ^ua_bytes::4, ^app_version::binary,
               0x8::4, ^principal_bytes::4, "principal",
               0x80>> =
               Encoder.encode(%Hello{extra: %Extra.Hello{scheme: "none"}}, "4.0.0")
    end

    test "handles encoding of Hello messages for >= 5.3" do
      app_version = "Neo4ex/#{@version}"
      elixir_version = "Elixir/#{System.build_info()[:version]}"
      user_agent_bytes = byte_size("user_agent")
      ua_bytes = byte_size(app_version)
      routing_bytes = byte_size("routing")
      bolt_agent_bytes = byte_size("bolt_agent")
      bolt_agent_product_bytes = byte_size("product")
      bolt_agent_language_bytes = byte_size("language")
      bolt_agent_language_value_bytes = byte_size(elixir_version)

      # even though Logon is a struct with prefdefined fields order, prior to 5.1 we're encoding it to the map so the keys will be sent according to map keys rules (compiler-defined, should be the same but can be random)
      assert <<0xB1, 0x01, 0xA3, 0x8::4, ^routing_bytes::4, "routing", 0xA0, 0x8::4,
               ^user_agent_bytes::4, "user_agent", 0x8::4, ^ua_bytes::4, ^app_version::binary,
               0x8::4, ^bolt_agent_bytes::4, "bolt_agent", 0xA2, 0x8::4,
               ^bolt_agent_product_bytes::4, "product", 0x8::4, ^ua_bytes::4,
               ^app_version::binary, 0x8::4, ^bolt_agent_language_bytes::4, "language", 0x8::4,
               ^bolt_agent_language_value_bytes::4,
               ^elixir_version::binary>> =
               Encoder.encode(%Hello{extra: %Extra.Hello{}}, "5.3.0")
    end
  end
end
