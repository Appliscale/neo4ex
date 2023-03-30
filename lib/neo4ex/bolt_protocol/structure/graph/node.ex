defmodule Neo4Ex.BoltProtocol.Structure.Graph.Node do
  use Neo4Ex.BoltProtocol.Structure

  # field order is important! its enforced by PackStream
  structure 0x4E do
    field(:id, default: nil)
    field(:labels, default: [])
    field(:properties, default: %{})
    field(:element_id, default: "", version: ">= 5.0.0")
  end
end
