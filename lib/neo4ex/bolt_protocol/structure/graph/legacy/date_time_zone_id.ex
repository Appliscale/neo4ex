defmodule Neo4Ex.BoltProtocol.Structure.Graph.Legacy.DateTimeZoneId do
  use Neo4Ex.BoltProtocol.Structure

  # field order is important! its enforced by PackStream
  structure 0x66 do
    field(:seconds, default: 0)
    field(:nanoseconds, default: 0)
    field(:tz_id, default: "")
  end

  def get_tag(bolt_version) do
    # since version 4.3 there is "Route" message with the same signature
    # we negotiate use of non-legacy version for 4.3/4.4
    # in 5.0+ this struct doesn't exist at all
    if Version.match?(bolt_version, ">= 4.3.0"), do: nil, else: @tag
  end
end
