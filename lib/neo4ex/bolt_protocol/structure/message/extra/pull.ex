defmodule Neo4ex.BoltProtocol.Structure.Message.Extra.Pull do
  use Neo4ex.BoltProtocol.Structure

  embeded_structure do
    field(:n, default: nil)
    field(:qid, default: nil)
  end
end
