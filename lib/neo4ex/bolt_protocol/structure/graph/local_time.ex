defmodule Neo4ex.BoltProtocol.Structure.Graph.LocalTime do
  use Neo4ex.BoltProtocol.Structure

  # Elixir supports 6-digit precission for time, this means we can use microsecodns but not nanoseconds
  # this library aims for simplicity, so we return "lost" nanoseconds as separate value
  structure 0x74 do
    field(:nanoseconds, default: 0)
  end

  def load([nanoseconds], _) do
    ns = rem(nanoseconds, 1000)

    time = Time.add(~T[00:00:00], nanoseconds, :nanosecond)

    {time, ns}
  end
end

defimpl Neo4ex.BoltProtocol.Encoder, for: Time do
  alias Neo4ex.BoltProtocol.Encoder
  alias Neo4ex.BoltProtocol.Structure.Graph.LocalTime

  def encode(struct, bolt_version) do
    Encoder.encode(
      %LocalTime{
        nanoseconds: Time.diff(struct, ~T[00:00:00], :nanosecond)
      },
      bolt_version
    )
  end
end
