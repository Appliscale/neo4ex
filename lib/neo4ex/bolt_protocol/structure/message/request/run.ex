defmodule Neo4Ex.BoltProtocol.Structure.Message.Request.Run do
  use Neo4Ex.BoltProtocol.Structure

  alias Neo4Ex.BoltProtocol.Structure.Message.Extra

  structure 0x10 do
    field(:query, default: "")
    field(:parameters, default: %{})
    field(:extra, default: %Extra.Begin{})
  end
end
