defmodule Neo4ex.BoltProtocol.Structure.Message.Summary.Failure do
  use Neo4ex.BoltProtocol.Structure

  structure 0x7F do
    field(:metadata, default: %{})
  end
end
