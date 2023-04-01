defmodule Neo4Ex.BoltProtocol.Structure.Graph.LocalDateTimeTest do
  use ExUnit.Case, async: true

  alias Neo4Ex.BoltProtocol.Structure.Graph.LocalDateTime
  alias Neo4Ex.BoltProtocol.Encoder

  describe "load/2" do
    test "returns NaiveDateTime with proper value" do
      assert NaiveDateTime.compare(
               ~N[1970-01-01 00:01:40.000002Z],
               LocalDateTime.load([100, 2000], nil)
             ) == :eq
    end
  end

  describe "Neo4Ex.BoltProtocol.Encoder" do
    test "encodes NaiveDateTime properly" do
      assert <<0xB2, 0x64, 100, 0xC9, 2000::16>> ==
               Encoder.encode(~N[1970-01-01 00:01:40.000002Z], "4.0.0")
    end
  end
end
