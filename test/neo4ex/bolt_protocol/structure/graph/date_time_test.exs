defmodule Neo4Ex.BoltProtocol.Structure.Graph.DateTimeTest do
  use ExUnit.Case, async: true

  alias Neo4Ex.BoltProtocol.Structure.Graph.DateTime, as: GraphDateTime
  alias Neo4Ex.BoltProtocol.Encoder

  describe "load/2" do
    test "returns DateTime with proper value" do
      {loaded, truncated} = GraphDateTime.load([100, 2123, 3600], nil)

      assert truncated == 123
      assert loaded.utc_offset == 3600

      assert DateTime.compare(
               ~U[1970-01-01 00:01:40.000002Z],
               loaded
             ) == :eq
    end
  end

  describe "Neo4Ex.BoltProtocol.Encoder" do
    test "encodes DateTime properly" do
      assert <<0xB3, 0x49, 100, 0xC9, 2000::16, 0>> ==
               Encoder.encode(~U[1970-01-01 00:01:40.000002Z], "4.0.0")

      assert <<0xB3, 0x49, 100, 0xC9, 2000::16, 0xC9, 3600::16>> ==
               ~U[1970-01-01 01:01:40.000002Z]
               # fake timezone change
               |> Map.put(:utc_offset, 3600)
               |> Encoder.encode("4.0.0")
    end
  end
end
