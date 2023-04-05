defmodule Neo4ex.BoltProtocol.Structure.Graph.UnboundRelationship do
  use Neo4ex.BoltProtocol.Structure

  # field order is important! its enforced by PackStream
  structure 0x72 do
    field(:id, default: nil)
    field(:type, default: "")
    field(:properties, default: %{})
  end
end
