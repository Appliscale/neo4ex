defmodule Neo4ex.BoltProtocol.Structure.Message.Request.Route do
  use Neo4ex.BoltProtocol.Structure

  alias Neo4ex.BoltProtocol.Structure.Message.Extra

  structure 0x66 do
    field(:routing, default: %{})
    field(:bookmarks, default: [])
    field(:db, default: "", version: "< 4.4.0")
    field(:extra, default: %Extra.Route{}, version: ">= 4.4.0")
  end

  # "Route" message exists since version 4.3
  def version_requirement(), do: ">= 4.3.0"
end
