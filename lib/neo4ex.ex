defmodule Neo4Ex do
  @moduledoc """
  Documentation for `Neo4Ex`.
  """

  alias Neo4Ex.Cypher

  @doc """
  Executes Cypher query on the database and returns Stream with results
  """
  def run(%Cypher.Query{} = query) do
    with(
      [{_, conn, _, [DBConnection]} | _] <- Supervisor.which_children(Neo4Ex.Connector),
      {:ok, query} <- DBConnection.prepare(conn, query),
      {:ok, _, result} <- DBConnection.execute(conn, query, [])
    ) do
      result
    else
      [] -> raise "Please add Neo4Ex.Connector to application Supervision tree"
      other -> other
    end
  end
end
