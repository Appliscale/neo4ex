defmodule Neo4Ex.BoltProtocol.Structure.Message.Extra.Hello do
  use Neo4Ex.BoltProtocol.Structure

  # can't be encoded directly, it's just helper for the Hello message
  embeded_structure do
    field(:user_agent, default: "Neo4Ex/0.1.0")
    field(:patch_bolt, default: ["utc"], version: ">= 4.3.0 and <= 4.4.0")
    field(:routing, default: %{}, version: ">= 4.1.0")

    # prior to v5.1, authentication is handled inside HELLO message
    field(:scheme, default: "", version: "< 5.1.0")
    field(:principal, default: "", version: "< 5.1.0")
    field(:credentials, default: "", version: "< 5.1.0")
  end
end
