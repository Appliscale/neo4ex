defmodule Neo4ex.BoltProtocol.Structure.Message.Summary.Success do
  use Neo4ex.BoltProtocol.Structure

  structure 0x70 do
    field(:metadata, default: %{})
  end
end
