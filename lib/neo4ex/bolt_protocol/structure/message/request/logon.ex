defmodule Neo4ex.BoltProtocol.Structure.Message.Request.Logon do
  use Neo4ex.BoltProtocol.Structure

  alias Neo4ex.BoltProtocol.Structure.Message.Extra

  structure 0x6A do
    field(:auth, default: %Extra.Logon{})
  end
end
