defmodule Neo4Ex.BoltProtocol.Structure.Graph.DateTime do
  use Neo4Ex.BoltProtocol.Structure

  # Elixir supports 6-digit precission for time, this means we can use microsecodns but not nanoseconds
  # this library aims for simplicity, so we just hide that detail and round to full microseconds
  # TODO: consider config option whether to keep lossless struct or map to lossy DateTime
  structure 0x49 do
    field(:seconds, default: 0)
    field(:nanoseconds, default: 0)
    field(:tz_offset_seconds, default: 0)
  end

  def load([seconds, nanoseconds, tz_offset_seconds], _) do
    dt =
      ~U[1970-01-01 00:00:00Z]
      |> DateTime.add(seconds + tz_offset_seconds, :second)
      |> DateTime.add(nanoseconds, :nanosecond)

    %{dt | utc_offset: tz_offset_seconds}
  end
end

defimpl Neo4Ex.BoltProtocol.Encoder, for: DateTime do
  alias Neo4Ex.BoltProtocol.Encoder
  alias Neo4Ex.BoltProtocol.Structure.Graph.DateTime, as: GraphDateTime

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
