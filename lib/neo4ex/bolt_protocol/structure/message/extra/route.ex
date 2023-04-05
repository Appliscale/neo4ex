defmodule Neo4ex.BoltProtocol.Structure.Message.Extra.Route do
  use Neo4ex.BoltProtocol.Structure

  embeded_structure do
    field(:db, default: "")
    field(:imp_user, default: "")
  end
end
