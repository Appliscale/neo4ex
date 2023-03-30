defmodule Neo4Ex.BoltProtocol.Structure.Graph.UnboundRelationship do
  use Neo4Ex.BoltProtocol.Structure

  # field order is important! its enforced by PackStream
  structure 0x72 do
    field(:id, default: nil)
    field(:type, default: "")
    field(:properties, default: %{})
  end
end
