defmodule Neo4Ex.BoltProtocol.Structure.Graph.DateTime do
  use Neo4Ex.BoltProtocol.Structure

  # field order is important! its enforced by PackStream
  structure 0x49 do
    field(:seconds, default: 0)
    field(:nanoseconds, default: 0)
    field(:tz_offset_seconds, default: 0)
  end
end
