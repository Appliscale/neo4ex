defmodule Neo4Ex.BoltProtocol.Structure.Message.Request.Begin do
  use Neo4Ex.BoltProtocol.Structure

  alias Neo4Ex.BoltProtocol.Structure.Message.Extra

  structure 0x11 do
    field(:extra, default: %Extra.Begin{})
  end
end
