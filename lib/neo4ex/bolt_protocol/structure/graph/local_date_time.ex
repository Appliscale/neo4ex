defmodule Neo4Ex.BoltProtocol.Structure.Graph.LocalDateTime do
  use Neo4Ex.BoltProtocol.Structure

  # field order is important! its enforced by PackStream
  structure 0x64 do
    field(:seconds, default: 0)
    field(:nanoseconds, default: 0)
  end
end
