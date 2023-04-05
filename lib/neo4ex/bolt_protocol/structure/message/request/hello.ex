defmodule Neo4ex.BoltProtocol.Structure.Message.Request.Hello do
  use Neo4ex.BoltProtocol.Structure

  alias Neo4ex.BoltProtocol.Structure.Message.Extra

  structure 0x01 do
    field(:extra, default: %Extra.Hello{})
  end
end
