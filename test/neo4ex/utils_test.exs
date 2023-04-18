defmodule Neo4ex.UtilsTest do
  use ExUnit.Case

  alias Neo4ex.Utils
  alias Neo4ex.PackStream.Exceptions

  describe "enumerable_header/2" do
    test "raises when collection is too big to encode" do
      assert_raise Exceptions.SizeError, fn -> Utils.enumerable_header(3_000_000_000, nil) end
    end
  end

  describe "require_modules/2" do
    test "waits for modules before compiling" do
      assert [Neo4ex.BoltProtocol.Structure] ==
               Utils.require_modules("neo4ex/bolt_protocol", "structure")
    end
  end

  describe "list_valid_versions/1" do
    test "filters invalid versions" do
      assert [] == Utils.list_valid_versions(">= 5.0.0")

      assert [Version.parse!("4.4.0"), Version.parse!("4.3.0")] ==
               Utils.list_valid_versions(">= 4.3.0")
    end
  end
end
