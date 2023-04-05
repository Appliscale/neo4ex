defmodule Neo4ex.BoltProtocol.Structure.Graph.LocalTimeTest do
  use ExUnit.Case, async: true

  alias Neo4ex.BoltProtocol.Structure.Graph.LocalTime
  alias Neo4ex.BoltProtocol.Encoder

  describe "load/2" do
    test "returns Time with proper value" do
      {loaded, truncated} = LocalTime.load([100_000_002_123], nil)

      assert truncated == 123

      assert Time.compare(
               ~T[00:01:40.000002],
               loaded
             ) == :eq
    end
  end

  describe "Neo4ex.BoltProtocol.Encoder" do
    test "encodes Time properly" do
      assert <<0xB1, 0x74, 0xCB, 100_000_002_000::64>> ==
               Encoder.encode(~T[00:01:40.000002], "4.0.0")
    end
  end
end
