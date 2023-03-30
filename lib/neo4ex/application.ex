defmodule Neo4Ex.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Neo4Ex.BoltProtocol.StructureRegistry
    ]

    opts = [strategy: :one_for_one, name: Neo4Ex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
