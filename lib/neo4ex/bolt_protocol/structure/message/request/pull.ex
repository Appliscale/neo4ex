defmodule Neo4ex.BoltProtocol.Structure.Message.Request.Pull do
  use Neo4ex.BoltProtocol.Structure

  alias Neo4ex.BoltProtocol.Structure.Message.Extra

  structure 0x3F do
    field(:extra, default: %Extra.Pull{})
  end
end
