defmodule Neo4Ex.BoltProtocol.Structure.Message.Request.Pull do
  use Neo4Ex.BoltProtocol.Structure

  alias Neo4Ex.BoltProtocol.Structure.Message.Extra

  structure 0x3F do
    field(:extra, default: %Extra.Pull{})
  end
end
