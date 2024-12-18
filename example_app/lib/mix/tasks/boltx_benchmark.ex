defmodule Mix.Tasks.ExampleApp.BoltxBenchmark do
  use Mix.Task

  alias Neo4ex.Cypher

  alias ExampleApp.Connector

  @requirements ["app.start"]

  @shortdoc "Runs benchmark to compare with boltx library"
  def run(_args) do
    Benchee.run(%{
      "Neo4ex" => fn -> neo4ex() end,
      "Boltx" => fn -> boltx() end
    })
  end

  def neo4ex() do
    %{query: query, params: params} = customer_query()
    Connector.run(%Cypher.Query{query: query, params: params})
  end

  def boltx() do
    %{query: query, params: params} = customer_query()
    Boltx.query!(Boltx, query, params)
  end

  def customer_query() do
    query = """
    MATCH (customer)
    RETURN customer, rand() as r
    ORDER BY r
    LIMIT 100
    """

    %{query: query, params: %{}}
  end
end
