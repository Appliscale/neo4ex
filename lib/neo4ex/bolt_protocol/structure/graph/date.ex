defmodule Neo4Ex.BoltProtocol.Structure.Graph.Date do
  use Neo4Ex.BoltProtocol.Structure

  # field order is important! its enforced by PackStream
  structure 0x44 do
    field(:days, default: 0)
  end

  def load([days], _) do
    Date.add(~D[1970-01-01], days)
  end
end

defimpl Neo4Ex.BoltProtocol.Encoder, for: Date do
  alias Neo4Ex.BoltProtocol.Encoder
  alias Neo4Ex.BoltProtocol.Structure.Graph.Date, as: GraphDate

  def encode(struct, bolt_version) do
    days = Date.diff(struct, ~D[1970-01-01])
    Encoder.encode(%GraphDate{days: days}, bolt_version)
  end
end
