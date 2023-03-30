defmodule Neo4Ex.BoltProtocol.Structure.Message.Extra.Pull do
  use Neo4Ex.BoltProtocol.Structure

  embeded_structure do
    field(:n, default: nil)
    field(:qid, default: nil)
  end
end
