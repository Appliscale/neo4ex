defmodule Neo4ex.BoltProtocol.Structure.Message.Extra.Begin do
  use Neo4ex.BoltProtocol.Structure

  embeded_structure do
    field(:bookmarks, default: [])
    field(:tx_timeout, default: nil)
    field(:tx_metadata, default: %{})
    field(:mode, default: "w")
    field(:db, default: nil, version: ">= 4.0.0")
    field(:imp_user, default: nil, version: ">= 4.4.0")
  end
end
