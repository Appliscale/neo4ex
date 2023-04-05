defmodule Neo4ex.BoltProtocol.Structure.Graph.Legacy.DateTimeZoneId do
  use Neo4ex.BoltProtocol.Structure

  # field order is important! its enforced by PackStream
  structure 0x66 do
    field(:seconds, default: 0)
    field(:nanoseconds, default: 0)
    field(:tz_id, default: "")
  end

  def version_requirement(), do: "< 4.3.0"
end
