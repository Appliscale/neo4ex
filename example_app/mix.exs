defmodule ExampleApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :example_app,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ExampleApp.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:neo4ex, path: "../"},
      {:bolt_sips, git: "https://github.com/florinpatrascu/bolt_sips", branch: "master"},
      {:faker, "~> 0.17.0"},
      {:jason, "~> 1.2"},
      {:benchee, "~> 1.0"}
    ]
  end
end
