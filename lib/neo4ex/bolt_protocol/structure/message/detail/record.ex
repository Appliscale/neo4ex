defmodule Neo4Ex.BoltProtocol.Structure.Message.Detail.Record do
  use Neo4Ex.BoltProtocol.Structure

  structure 0x71 do
    field(:data, default: [])
  end
end
