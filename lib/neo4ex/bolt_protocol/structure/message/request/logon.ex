defmodule Neo4Ex.BoltProtocol.Structure.Message.Request.Logon do
  use Neo4Ex.BoltProtocol.Structure

  # TODO: implement validation
  # @predefined_schemes ~w(none basic bearer kerberos)

  structure 0x6A do
    field(:scheme, default: "")
    field(:principal, default: "")
    field(:credentials, default: "")
  end
end
