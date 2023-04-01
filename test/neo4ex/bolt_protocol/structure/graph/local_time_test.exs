defmodule Neo4Ex.BoltProtocol.Structure.Graph.LocalTimeTest do
  use ExUnit.Case, async: true

  alias Neo4Ex.BoltProtocol.Structure.Graph.LocalTime
  alias Neo4Ex.BoltProtocol.Encoder

  describe "load/2" do
    test "returns Time with proper value" do
      assert Time.compare(
               ~T[00:01:40.000002],
               LocalTime.load([100_000_002_000], nil)
             ) == :eq
    end
  end

  describe "Neo4Ex.BoltProtocol.Encoder" do
    test "encodes Time properly" do
      assert <<0xB1, 0x74, 0xCB, 100_000_002_000::64>> ==
               Encoder.encode(~T[00:01:40.000002], "4.0.0")
    end
  end
end
