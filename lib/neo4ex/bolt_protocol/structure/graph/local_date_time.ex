defmodule Neo4Ex.BoltProtocol.Structure.Graph.LocalDateTime do
  use Neo4Ex.BoltProtocol.Structure

  # Elixir supports 6-digit precission for time, this means we can use microsecodns but not nanoseconds
  # this library aims for simplicity, so we just hide that detail and round to full microseconds
  # TODO: consider config option whether to keep lossless struct or map to lossy DateTime
  structure 0x64 do
    field(:seconds, default: 0)
    field(:nanoseconds, default: 0)
  end

  def load([seconds, nanoseconds], _) do
    ~N[1970-01-01 00:00:00]
    |> NaiveDateTime.add(seconds, :second)
    |> NaiveDateTime.add(nanoseconds, :nanosecond)
  end
end

defimpl Neo4Ex.BoltProtocol.Encoder, for: NaiveDateTime do
  alias Neo4Ex.BoltProtocol.Encoder
  alias Neo4Ex.BoltProtocol.Structure.Graph.LocalDateTime

  def encode(struct, bolt_version) do
    second_in_ns = Integer.pow(10, 9)
    nanoseconds = NaiveDateTime.diff(struct, ~N[1970-01-01 00:00:00], :nanosecond)
    seconds = div(nanoseconds, second_in_ns)
    nanoseconds = rem(nanoseconds, second_in_ns)

    Encoder.encode(
      %LocalDateTime{
        seconds: seconds,
        nanoseconds: nanoseconds
      },
      bolt_version
    )
  end
end
