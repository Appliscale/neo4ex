defmodule Neo4ex.BoltProtocol.Structure.Graph.Time do
  use Neo4ex.BoltProtocol.Structure

  # field order is important! its enforced by PackStream
  structure 0x54 do
    field(:nanoseconds, default: 0)
    field(:tz_offset_seconds, default: 0)
  end
end
