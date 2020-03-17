defmodule Rackspace.Middleware.Auth do
  @behaviour Tesla.Middleware

  alias Rackspace.{Config, Identity}

  def call(env, next, _opts) do
    Identity.refresh()

    env
    |> put_auth_headers()
    |> Tesla.run(next)
  end

  defp put_auth_headers(%Tesla.Env{} = env) do
    Tesla.put_header(env, "x-auth-token", Config.get(:token))
  end
end
