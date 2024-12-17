defmodule Neo4ex.MixProject do
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
          ~r/^Neo4ex.BoltProtocol.Structure/,
          Neo4ex.PackStream.DecoderBuilder
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
      {:db_connection, "~> 2.6.0"},

      # Tests
      {:mox, "~> 1.0", only: [:test]},

      # Linting
      {:credo, "~> 1.6.7", only: [:dev]},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},

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
        Neo4ex.BoltProtocol,
        Neo4ex.PackStream,
        Neo4ex.BoltProtocol.Structure.Graph,
        Neo4ex.BoltProtocol.Structure.Graph.Legacy,
        Neo4ex.BoltProtocol.Structure.Message.Request,
        Neo4ex.BoltProtocol.Structure.Message.Detail,
        Neo4ex.BoltProtocol.Structure.Message.Summary,
        Neo4ex.BoltProtocol.Structure.Message.Extra
      ],
      groups_for_modules: [
        Structure: ~r/BoltProtocol\.Structure\.Graph/,
        Message: ~r/BoltProtocol\.Structure\.Message/
      ]
    ]
  end
end
