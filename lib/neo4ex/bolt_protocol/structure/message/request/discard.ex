defmodule Neo4Ex.BoltProtocol.Structure.Message.Request.Discard do
  use Neo4Ex.BoltProtocol.Structure

  alias Neo4Ex.BoltProtocol.Structure.Message.Extra

  structure 0x2F do
    field(:extra, default: %Extra.Pull{})
  end
end
