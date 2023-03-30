defmodule Neo4Ex.BoltProtocol.Structure.Message.Request.Route do
  use Neo4Ex.BoltProtocol.Structure

  alias Neo4Ex.BoltProtocol.Structure.Message.Extra

  structure 0x66 do
    field(:routing, default: %{})
    field(:bookmarks, default: [])
    field(:db, default: "", version: "< 4.4.0")
    field(:extra, default: %Extra.Route{}, version: ">= 4.4.0")
  end
end
