defmodule Neo4Ex.Cypher.QueryTest do
  use ExUnit.Case, async: true

  alias Neo4Ex.Cypher.Query

  describe "DBConnection.Query" do
    test "parse/2 ensures that params are map" do
      q = %Query{}
      assert q == DBConnection.Query.parse(%Query{}, [])
      assert q == DBConnection.Query.parse(%Query{params: nil}, [])
    end

    test "describe/2 doesn't manipulate query" do
      q = %Query{query: "asd", params: %{a: 1}}
      assert q == DBConnection.Query.describe(q, [])
    end

    test "encode/2 doesn't manipulate query" do
      q = %Query{query: "asd", params: %{a: 1}}
      assert q == DBConnection.Query.encode(q, %{}, [])
    end

    test "decode/2 doesn't manipulate query" do
      q = %Query{query: "asd", params: %{a: 1}}
      assert "abc" == DBConnection.Query.decode(q, "abc", [])
    end
  end
end
