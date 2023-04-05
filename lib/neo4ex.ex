defmodule Neo4ex do
  @moduledoc """
  Documentation for `Neo4ex`.
  """

  alias Neo4ex.Cypher

  @doc """
  Executes Cypher query on the database and returns results.
  This function always reads all data and returns a list of results.
  If you need more control, use `stream/2`.
  """
  def run(%Cypher.Query{} = query) do
    case prepare_query(query) do
      {:ok, args} -> apply(DBConnection, :execute, args)
      other -> other
    end
  end

  @doc """
  Executes Cypher query on the database and returns results.
  This function uses reducer to read data from stream.
  Reducer may finish prematurely. In that case, remaining part of the stream will be thrown away.
  """
  def stream(%Cypher.Query{} = query, reducer) when is_function(reducer, 2) do
    with(
      {:ok, [conn | args]} <- prepare_query(query),
      {:ok, stream} <-
        DBConnection.transaction(conn, fn conn ->
          # we have to consume stream within transaction
          DBConnection
          |> apply(:stream, [conn | args])
          |> Stream.reject(&is_nil/1)
          |> Enum.reduce_while([], reducer)
        end)
    ) do
      stream
    end
  end

  def transaction(func) when is_function(func, 1) do
    case Supervisor.which_children(Neo4ex.Connector) do
      [{_, conn, _, [DBConnection]} | _] -> DBConnection.transaction(conn, func)
      [] -> raise "Please add Neo4ex.Connector to application Supervision tree"
    end
  end

  defp prepare_query(query) do
    with(
      [{_, conn, _, [DBConnection]} | _] <- Supervisor.which_children(Neo4ex.Connector),
      {:ok, query} <- DBConnection.prepare(conn, query)
    ) do
      {:ok, [conn, query, []]}
    else
      [] -> raise "Please add Neo4ex.Connector to application Supervision tree"
      other -> other
    end
  end
end
