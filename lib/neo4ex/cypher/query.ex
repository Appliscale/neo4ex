defmodule Neo4Ex.Cypher.Query do
  @moduledoc """
  This module is responsible for generating Cypher queries that can be passed to the `Neo4Ex.run/1` or `Neo4Ex.stream/2`
  """

  alias Neo4Ex.Cypher.Query

  defstruct query: "", params: %{}, opts: []

  defimpl DBConnection.Query do
    def parse(%Query{params: %{}} = query, _opts), do: query

    def parse(%Query{params: params} = query, _opts) do
      # make sure params is map
      params =
        case params do
          nil -> %{}
        end

      %{query | params: params}
    end

    def describe(query, _opts), do: query
    # encode/decode happens in the protocol because it requires knowledge of protocol version
    def encode(query, _params, _opts), do: query
    def decode(_query, result, _opts), do: result
  end
end
