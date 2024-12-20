defmodule ExampleApp do
  @moduledoc """
  Documentation for `ExampleApp`.
  """

  import Neo4ex.Cypher.Query

  alias Neo4ex.BoltProtocol.Structure.Message.Summary.Success
  alias Neo4ex.BoltProtocol.Structure.Graph.{Node, Path}
  alias Neo4ex.Cypher
  alias ExampleApp.Connector
  alias ExampleApp.Schema.{Customer, Organization}

  def hello do
    country = "Nepal"

    query =
      match(
        customer: %Organization{country: country} <- [:customer_of] - %Customer{},
        org: %Organization{},
        nothing: %{},
        return: customer,
        limit: 5
      )

    {:ok, _query, results} = Connector.run(query)

    results
    |> Enum.reject(fn msg -> match?(%Success{}, msg) end)
    |> Enum.map(fn
      [%Path{nodes: nodes}] ->
        Enum.map(nodes, &node_to_struct/1)

      [%Node{}] = node ->
        node_to_struct(node)
    end)
  end

  def hello_stream do
    query = """
    MATCH (customer:Customer {company: $company})
    RETURN customer
    LIMIT 10
    """

    Connector.transaction(fn ->
      %Cypher.Query{query: query, params: %{company: "Davenport Inc"}}
      |> Connector.stream()
      |> Enum.reduce_while([], fn msg, acc ->
        case msg do
          [%Node{properties: properties}] ->
            properties = Map.new(properties, fn {k, v} -> {String.to_atom(k), v} end)
            {:cont, [struct(Customer, properties) | acc]}

          _ ->
            {:halt, acc}
        end
      end)
    end)
  end

  defp node_to_struct(%{labels: [label], properties: properties}) do
    properties = Map.new(properties, fn {k, v} -> {String.to_atom(k), v} end)

    label
    |> String.to_existing_atom()
    |> struct(properties)
  end
end
