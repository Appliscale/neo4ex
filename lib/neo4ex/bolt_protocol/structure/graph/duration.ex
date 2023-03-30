defmodule Neo4Ex.BoltProtocol.Structure.Graph.Duration do
  use Neo4Ex.BoltProtocol.Structure

  # field order is important! its enforced by PackStream
  structure 0x45 do
    field(:months, default: 0)
    field(:days, default: 0)
    field(:seconds, default: 0)
    field(:nanoseconds, default: 0)
  end
end
