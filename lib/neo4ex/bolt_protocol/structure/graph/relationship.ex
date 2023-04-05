defmodule Neo4ex.BoltProtocol.Structure.Graph.Relationship do
  use Neo4ex.BoltProtocol.Structure

  # field order is important! its enforced by PackStream
  structure 0x52 do
    field(:id, default: nil)
    field(:startNodeId, default: nil)
    field(:endNodeId, default: nil)
    field(:type, default: "")
    field(:properties, default: %{})
  end
end
