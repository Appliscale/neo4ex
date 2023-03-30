defmodule Neo4Ex.BoltProtocol.Structure.Message.Summary.Failure do
  use Neo4Ex.BoltProtocol.Structure

  structure 0x7F do
    field(:metadata, default: %{})
  end
end
