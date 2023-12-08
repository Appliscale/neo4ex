defmodule Neo4ex.Cypher.Stream do
  @moduledoc false
  alias Neo4ex.Cypher.Query

  defstruct pool: nil, query: nil

  defimpl Enumerable do
    def count(_), do: {:error, __MODULE__}

    def member?(_, _), do: {:error, __MODULE__}

    def slice(_), do: {:error, __MODULE__}

    def reduce(
          %Neo4ex.Cypher.Stream{
            pool: pool,
            query: %Query{params: params, opts: opts} = query
          },
          acc,
          fun
        ) do
      Neo4ex.Connector.reduce(pool, query, params, opts, acc, fun)
    end
  end

  defimpl Collectable do
    def into(
          %Neo4ex.Cypher.Stream{
            pool: pool,
            query: %Query{params: params, opts: opts} = query
          } = stream
        ) do
      {state, fun} = Neo4ex.Connector.into(pool, query, params, opts)
      {state, make_into(fun, stream)}
    end

    defp make_into(fun, stream) do
      fn
        state, :done ->
          fun.(state, :done)
          stream

        state, acc ->
          fun.(state, acc)
      end
    end
  end
end
