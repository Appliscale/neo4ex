defmodule Neo4Ex.BoltProtocol.Structure.Message.Summary.Success do
  use Neo4Ex.BoltProtocol.Structure

  structure 0x70 do
    field(:metadata, default: %{})
  end
end
