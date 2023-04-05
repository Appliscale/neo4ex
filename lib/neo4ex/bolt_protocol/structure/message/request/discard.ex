defmodule Neo4ex.BoltProtocol.Structure.Message.Request.Discard do
  use Neo4ex.BoltProtocol.Structure

  alias Neo4ex.BoltProtocol.Structure.Message.Extra

  structure 0x2F do
    field(:extra, default: %Extra.Pull{})
  end
end
