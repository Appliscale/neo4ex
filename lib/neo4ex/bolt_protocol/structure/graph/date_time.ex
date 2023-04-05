defmodule Neo4ex.BoltProtocol.Structure.Graph.DateTime do
  use Neo4ex.BoltProtocol.Structure

  # Elixir supports 6-digit precission for time, this means we can use microsecodns but not nanoseconds
  # this library aims for simplicity, so we return "lost" nanoseconds as separate value
  structure 0x49 do
    field(:seconds, default: 0)
    field(:nanoseconds, default: 0)
    field(:tz_offset_seconds, default: 0)
  end

  def load([seconds, nanoseconds, tz_offset_seconds], _) do
    ns = rem(nanoseconds, 1000)

    dt =
      ~U[1970-01-01 00:00:00Z]
      |> DateTime.add(seconds + tz_offset_seconds, :second)
      |> DateTime.add(nanoseconds, :nanosecond)

    {%{dt | utc_offset: tz_offset_seconds}, ns}
  end
end

defimpl Neo4ex.BoltProtocol.Encoder, for: DateTime do
  alias Neo4ex.BoltProtocol.Encoder
  alias Neo4ex.BoltProtocol.Structure.Graph.DateTime, as: GraphDateTime

  def encode(%DateTime{utc_offset: utc_offset} = struct, bolt_version) do
    second_in_ns = Integer.pow(10, 9)
    nanoseconds = DateTime.diff(struct, ~U[1970-01-01 00:00:00Z], :nanosecond)
    seconds = div(nanoseconds, second_in_ns)
    nanoseconds = rem(nanoseconds, second_in_ns)

    Encoder.encode(
      %GraphDateTime{
        seconds: seconds,
        nanoseconds: nanoseconds,
        tz_offset_seconds: utc_offset
      },
      bolt_version
    )
  end
end
