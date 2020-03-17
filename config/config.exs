use Mix.Config

config :tesla, adapter: Tesla.Adapter.Mint

if Mix.env() == :test do
  import_config "test.exs"
end
