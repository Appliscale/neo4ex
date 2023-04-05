defmodule Neo4ex.BoltProtocol.Structure.Message.Request.Begin do
  use Neo4ex.BoltProtocol.Structure

  alias Neo4ex.BoltProtocol.Structure.Message.Extra

  structure 0x11 do
    field(:extra, default: %Extra.Begin{})
  end
end
