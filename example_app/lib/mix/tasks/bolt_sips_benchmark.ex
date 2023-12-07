defmodule Mix.Tasks.ExampleApp.BoltSipsBenchmark do
  use Mix.Task

  alias Neo4ex.Cypher

  alias Bolt.Sips, as: Neo

  alias ExampleApp.Connector

  @requirements ["app.start"]

  @shortdoc "Runs benchmark to compare with bolt_sips library"
  def run(_args) do
    Benchee.run(%{
      "Neo4ex" => fn -> neo4ex() end,
      "Bolt.Sips" => fn -> bolt_sips() end
    })
  end

  def neo4ex() do
    %{query: query, params: params} = customer_query()
    Connector.run(%Cypher.Query{query: query, params: params})
  end

  def bolt_sips() do
    %{query: query, params: params} = customer_query()
    Neo.query!(Neo.conn(), query, params)
  end

  def customer_query() do
    query = """
    MATCH (customer)
    RETURN customer, rand() as r
    ORDER BY r
    LIMIT 10
    """

    %{query: query, params: %{}}
  end
end
