defmodule Neo4Ex.BoltProtocol.Structure.Message.Request.Hello do
  use Neo4Ex.BoltProtocol.Structure

  alias Neo4Ex.BoltProtocol.Structure.Message.Extra

  structure 0x01 do
    field(:extra, default: %Extra.Hello{})
  end
end
