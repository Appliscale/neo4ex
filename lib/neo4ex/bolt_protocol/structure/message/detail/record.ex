defmodule Neo4ex.BoltProtocol.Structure.Message.Detail.Record do
  use Neo4ex.BoltProtocol.Structure

  structure 0x71 do
    field(:data, default: [])
  end
end
