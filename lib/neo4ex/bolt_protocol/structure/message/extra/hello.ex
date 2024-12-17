defmodule Neo4ex.BoltProtocol.Structure.Message.Extra.Hello do
  use Neo4ex.BoltProtocol.Structure

  @version Mix.Project.config()[:version]
  @system_info System.build_info()[:version]

  # can't be encoded directly, it's just helper for the Hello message
  embeded_structure do
    field(:user_agent, default: "Neo4ex/#{@version}")

    field(:bolt_agent,
      default: %{
        product: "Neo4ex/#{@version}",
        language: "Elixir/#{@system_info}"
      },
      version: ">= 5.3.0"
    )

    field(:patch_bolt, default: ["utc"], version: ">= 4.3.0 and <= 4.4.0")
    field(:routing, default: %{}, version: ">= 4.1.0")

    # prior to v5.1, authentication is handled inside HELLO message
    field(:scheme, version: "< 5.1.0")
    field(:principal, version: "< 5.1.0")
    field(:credentials, version: "< 5.1.0")
  end
end
