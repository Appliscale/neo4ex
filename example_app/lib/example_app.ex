defmodule ExampleApp do
  @moduledoc """
  Documentation for `ExampleApp`.
  """

  alias Neo4ex.BoltProtocol.Structure.Message.Summary.Success
  alias Neo4ex.BoltProtocol.Structure.Graph.Node
  alias Neo4ex.Cypher
  alias ExampleApp.Connector
  alias ExampleApp.Schema.Customer

  def hello do
    query = """
    MATCH (customer:Customer {company: $company})
    RETURN customer
    LIMIT 10
    """

    {:ok, _query, results} =
      Connector.run(%Cypher.Query{query: query, params: %{company: "Davenport Inc"}})

    results
    |> Enum.reject(fn msg -> match?(%Success{}, msg) end)
    |> Enum.map(fn [%Node{properties: properties}] ->
      properties = Map.new(properties, fn {k, v} -> {String.to_atom(k), v} end)
      struct(Customer, properties)
    end)
  end

  def hello_stream do
    query = """
    MATCH (customer:Customer {company: $company})
    RETURN customer
    LIMIT 10
    """

    %Cypher.Query{query: query, params: %{company: "Davenport Inc"}}
    |> Connector.stream(fn msg, acc ->
      case msg do
        [%Node{properties: properties}] ->
          properties = Map.new(properties, fn {k, v} -> {String.to_atom(k), v} end)
          {:cont, [struct(Customer, properties) | acc]}

        _ ->
          {:halt, acc}
      end
    end)
    |> Enum.to_list()
  end
end
