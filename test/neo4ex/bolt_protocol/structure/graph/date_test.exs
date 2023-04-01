defmodule Neo4Ex.BoltProtocol.Structure.Graph.DateTest do
  use ExUnit.Case, async: true

  alias Neo4Ex.BoltProtocol.Structure.Graph.Date, as: GraphDate
  alias Neo4Ex.BoltProtocol.Encoder

  describe "load/2" do
    test "returns Date with proper value" do
      assert Date.compare(~D[1970-01-31], GraphDate.load([30], nil)) == :eq
    end
  end

  describe "Neo4Ex.BoltProtocol.Encoder" do
    test "encodes Date properly" do
      assert <<0xB1, 0x44, 30>> == Encoder.encode(~D[1970-01-31], "4.0.0")
    end
  end
end
