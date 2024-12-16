defmodule Neo4ex.BoltProtocol.Structure.Message.Extra.Logon do
  use Neo4ex.BoltProtocol.Structure

  # TODO: implement validation
  # @predefined_schemes ~w(none basic bearer kerberos)

  embeded_structure do
    field(:scheme, default: "")
    field(:principal, default: "")
    field(:credentials, default: "")
  end
end
