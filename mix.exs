defmodule Rackspace.Deprecated.Mixfile do
  use Mix.Project

  def project do
    [
      app: :rackspace,
      version: "0.1.0",
      elixir: "~> 1.8",
      deps: deps(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod
    ]
  end

  def application do
    [
      applications: [:logger],
      mod: {Rackspace, []}
    ]
  end

  defp deps do
    [
      {:castore, "~> 0.1.0"},
      {:jason, "~> 1.1.2"},
      {:mint, "~> 1.0"},
      {:timex, "~> 3.6.1"}
    ]
  end
end
