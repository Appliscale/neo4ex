defmodule Neo4Ex.BoltProtocol.Structure.Graph.LocalTime do
  use Neo4Ex.BoltProtocol.Structure

  # field order is important! its enforced by PackStream
  structure 0x74 do
    field(:nanoseconds, default: 0)
  end

  def load([nanoseconds], _) do
    Time.add(~T[00:00:00], nanoseconds, :nanosecond)
  end
end

defimpl Neo4Ex.BoltProtocol.Encoder, for: Time do
  alias Neo4Ex.BoltProtocol.Encoder
  alias Neo4Ex.BoltProtocol.Structure.Graph.LocalTime

  def encode(struct, bolt_version) do
    Encoder.encode(
      %LocalTime{
        nanoseconds: Time.diff(struct, ~T[00:00:00], :nanosecond)
      },
      bolt_version
    )
  end
end
