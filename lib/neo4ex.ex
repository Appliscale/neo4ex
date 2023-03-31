defmodule Neo4Ex do
  @moduledoc """
  Documentation for `Neo4Ex`.
  """

  alias Neo4Ex.Cypher

  @doc """
  Executes Cypher query on the database and returns results
  """
  def run(%Cypher.Query{} = query) do
    case prepare_query(query) do
      {:ok, args} -> apply(DBConnection, :execute, args)
      other -> other
    end
  end

  def stream(%Cypher.Query{} = query, reducer) when is_function(reducer, 2) do
    with(
      {:ok, [conn | args]} <- prepare_query(query),
      {:ok, stream} <-
        DBConnection.transaction(conn, fn conn ->
          # we have to consume stream within transaction
          DBConnection
          |> apply(:stream, [conn | args])
          |> Stream.reject(&is_nil/1)
          |> Enum.reduce(reducer)
        end)
    ) do
      stream
    end
  end

  defp prepare_query(query) do
    with(
      [{_, conn, _, [DBConnection]} | _] <- Supervisor.which_children(Neo4Ex.Connector),
      {:ok, query} <- DBConnection.prepare(conn, query)
    ) do
      {:ok, [conn, query, []]}
    else
      [] -> raise "Please add Neo4Ex.Connector to application Supervision tree"
      other -> other
    end
  end
end
