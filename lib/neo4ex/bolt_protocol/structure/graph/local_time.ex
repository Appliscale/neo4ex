defmodule Neo4Ex.BoltProtocol.Structure.Graph.LocalTime do
  use Neo4Ex.BoltProtocol.Structure

  # field order is important! its enforced by PackStream
  structure 0x74 do
    field(:nanoseconds, default: 0)
  end
end
