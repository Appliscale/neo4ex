defmodule Neo4ex.BoltProtocol.Structure.Graph.Point3d do
  use Neo4ex.BoltProtocol.Structure

  # field order is important! its enforced by PackStream
  structure 0x59 do
    field(:srid, default: 0)
    field(:x, default: 0)
    field(:y, default: 0)
    field(:z, default: 0)
  end
end
