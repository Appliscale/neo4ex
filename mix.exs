defmodule Neo4Ex.MixProject do
  use Mix.Project

  @source_url "https://github.com/appliscale/neo4ex"
  @version "0.1.0"

  def project do
    [
      app: :neo4ex,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      description: description(),
      package: package(),
      deps: deps(),
      docs: docs(),
      test_coverage: [
        ignore_modules: [
          Neo4Ex.BoltProtocol.Structure,
          Neo4Ex.PackStream.DecoderBuilder,
          Neo4Ex.PackStream.Exceptions.MarkersError
        ],
        summary: [
          threshold: 80
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:db_connection, "~> 2.4"},

      # Tests
      {:mox, "~> 1.0", only: [:test]},

      # Linting
      {:credo, "~> 1.6.7", only: [:dev]},
      {:dialyxir, "~> 1.2.0", only: [:dev], runtime: false},

      # Documentation
      # Run with: `mix docs`
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "Neo4j driver and DSL for Elixir"
  end

  defp package do
    [
      maintainers: ["Cichacz"],
      licenses: ["MIT"],
      links: %{"github" => @source_url},
      files: [
        "lib",
        "mix.exs",
        "README.md",
        "LICENSE"
      ]
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "CHANGELOG.md"
      ],
      source_ref: "v#{@version}",
      source_url: @source_url,
      nest_modules_by_prefix: [
        Neo4Ex.BoltProtocol,
        Neo4Ex.PackStream,
        Neo4Ex.BoltProtocol.Structure.Graph,
        Neo4Ex.BoltProtocol.Structure.Graph.Legacy,
        Neo4Ex.BoltProtocol.Structure.Message.Request,
        Neo4Ex.BoltProtocol.Structure.Message.Detail,
        Neo4Ex.BoltProtocol.Structure.Message.Summary,
        Neo4Ex.BoltProtocol.Structure.Message.Extra
      ],
      groups_for_modules: [
        Structure: ~r/BoltProtocol\.Structure\.Graph/,
        Message: ~r/BoltProtocol\.Structure\.Message/
      ]
    ]
  end
end
