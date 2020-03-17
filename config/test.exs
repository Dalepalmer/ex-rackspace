use Mix.Config

config :logger, level: :error

config :tesla, adapter: Tesla.Mock

config :rackspace, :api,
  username: "test_user",
  password: "test_pass"
