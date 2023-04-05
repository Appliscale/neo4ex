defmodule Neo4ex.BoltProtocol.Structure.Message.Request.Run do
  use Neo4ex.BoltProtocol.Structure

  alias Neo4ex.BoltProtocol.Structure.Message.Extra

  structure 0x10 do
    field(:query, default: "")
    field(:parameters, default: %{})
    field(:extra, default: %Extra.Begin{})
  end
end
