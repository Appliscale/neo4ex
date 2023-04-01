defmodule Neo4Ex.BoltProtocol.Structure.Message.Request.Route do
  use Neo4Ex.BoltProtocol.Structure

  alias Neo4Ex.BoltProtocol.Structure.Message.Extra

  structure 0x66 do
    field(:routing, default: %{})
    field(:bookmarks, default: [])
    field(:db, default: "", version: "< 4.4.0")
    field(:extra, default: %Extra.Route{}, version: ">= 4.4.0")
  end

  def get_tag(bolt_version) do
    # "Route" message exists since version 4.3
    if Version.match?(bolt_version, "< 4.3.0"), do: nil, else: @tag
  end
end
