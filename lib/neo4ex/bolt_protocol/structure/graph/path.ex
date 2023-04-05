defmodule Neo4ex.BoltProtocol.Structure.Graph.Path do
  use Neo4ex.BoltProtocol.Structure

  # field order is important! its enforced by PackStream
  structure 0x50 do
    field(:nodes, default: [])
    field(:rels, default: [])
    field(:indices, default: [])
  end
end
