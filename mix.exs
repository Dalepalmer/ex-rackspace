defmodule Rackspace.Deprecated.Mixfile do
  use Mix.Project

  def project do
    [
      app: :rackspace,
      version: "2.0.0",
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger],
      mod: {Rackspace, []}
    ]
  end

  defp deps do
    [
      {:castore, "~> 0.1.0"},
      {:jason, "~> 1.1.2"},
      {:mint, "~> 1.0"},
      {:tesla, "~> 1.3.0"}
    ]
  end
end
