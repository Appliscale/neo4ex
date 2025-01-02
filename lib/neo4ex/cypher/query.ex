defmodule Neo4ex.Cypher.Query do
  @moduledoc """
  This module is responsible for generating Cypher queries that can be passed to the `Neo4ex.run/1` or `Neo4ex.stream/2`
  """

  alias Neo4ex.Cypher.Query

  defstruct query: [], params: %{}, opts: []

  ## Top level operations ##

  @match_ops [:return, :delete, :with, :unwind, :limit]
  defmacro match(query_parts) do
    {ast, query_parts} =
      Macro.postwalk(query_parts, [], fn
        {match_op, value}, acc when match_op in @match_ops ->
          match_op = match_op |> Atom.to_string() |> String.upcase()
          value = extract_value(value)
          {nil, ["#{match_op} #{value}" | acc]}

        {:<-, _, [to, {:-, _, [[rel], from]}]}, acc ->
          rel = rel |> Atom.to_string() |> String.upcase()
          from_ast = extract_label_with_filters(from, __CALLER__)
          to_ast = extract_label_with_filters(to, __CALLER__)

          expr =
            quote do
              "(:#{unquote(from_ast)})-[:#{unquote(rel)}]->(:#{unquote(to_ast)})"
            end

          {nil, [expr | acc]}

        ast, acc ->
          {ast, acc}
      end)

    match_ops =
      Enum.map(@match_ops, fn match_op -> match_op |> Atom.to_string() |> String.upcase() end)

    outstanding_identifiers =
      Enum.filter(ast, fn
        {identifier, nil} -> is_atom(identifier)
        _ -> false
      end)

    query_string =
      query_parts
      |> Enum.reverse()
      |> Enum.with_index()
      |> Enum.map(fn {elem, idx} ->
        if is_binary(elem) && Enum.any?(match_ops, &String.starts_with?(elem, &1)) do
          elem
        else
          {identifier, nil} = Enum.at(outstanding_identifiers, idx)

          quote do
            "#{unquote(identifier)} = #{unquote(elem)}"
          end
        end
      end)

    quote do
      %Query{
        query: "MATCH " <> Enum.join(unquote(query_string), " ")
      }
    end
  end

  defp extract_value({var, _, _}), do: var
  defp extract_value(val), do: val

  defp extract_label_with_filters(ast, env) do
    {_, label} =
      Macro.prewalk(ast, nil, fn
        {:__aliases__, _, _} = ast, _acc ->
          {nil, "`#{Macro.expand(ast, env)}`"}

        ast, acc ->
          {ast, acc}
      end)

    {_, filters} =
      Macro.prewalk(ast, [], fn
        {:%{}, _, filters}, _acc ->
          {nil, filters}

        ast, acc ->
          {ast, acc}
      end)

    quote do
      "#{unquote(label)}{#{Enum.map(unquote(filters), fn {k, v} -> "#{k}: \"#{v}\"" end)}}"
    end
  end

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
