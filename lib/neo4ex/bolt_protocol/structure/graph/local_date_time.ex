defmodule Neo4ex.BoltProtocol.Structure.Graph.LocalDateTime do
  use Neo4ex.BoltProtocol.Structure

  require Logger

  # Elixir supports 6-digit precission for time, this means we can use microsecodns but not nanoseconds
  # this library aims for simplicity, so we return "lost" nanoseconds as separate value
  structure 0x64 do
    field(:seconds, default: 0)
    field(:nanoseconds, default: 0)
  end

  def load([seconds, nanoseconds], _) do
    ns = rem(nanoseconds, 1000)

    date =
      ~N[1970-01-01 00:00:00]
      |> NaiveDateTime.add(seconds, :second)
      |> NaiveDateTime.add(nanoseconds, :nanosecond)

    {date, ns}
  end
end

defimpl Neo4ex.BoltProtocol.Encoder, for: NaiveDateTime do
  alias Neo4ex.BoltProtocol.Encoder
  alias Neo4ex.BoltProtocol.Structure.Graph.LocalDateTime

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
