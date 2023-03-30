defmodule Neo4Ex.BoltProtocol.Structure.Graph.DateTimeZoneId do
  use Neo4Ex.BoltProtocol.Structure

  # field order is important! its enforced by PackStream
  structure 0x69 do
    field(:seconds, default: 0)
    field(:nanoseconds, default: 0)
    field(:tz_id, default: "")
  end
end
