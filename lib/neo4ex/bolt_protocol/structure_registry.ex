defprotocol Neo4Ex.BoltProtocol.StructureRegistry do
  @moduledoc false

  def get_tag(struct, bolt_version)
end
