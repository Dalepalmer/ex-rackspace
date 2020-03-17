defmodule Rackspace.IdentityTest do
  use ExUnit.Case, async: false
  import Tesla.Mock
  import Rackspace.Test.JsonFixture
  alias Rackspace.{Identity, Config}

  setup do
    mock(fn %{method: :post, url: "https://identity.api.rackspacecloud.com/v2.0/tokens"} ->
      fixture("identity.json")
    end)

    on_exit(fn -> Agent.update(Config, fn _ -> Config.default() end) end)
  end

  defp in_the_future do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.add(100)
    |> NaiveDateTime.to_iso8601()
  end

  defp preload_valid_credentials do
    Config.set(%{token: "test_token", expires_at: in_the_future()})
  end

  test "fetches credentials and populates service cache" do
    assert Identity.refresh() == :ok
  end

  test "skips if valid credentials are already cached" do
    preload_valid_credentials()
    assert Identity.refresh() == false
  end

  test "forces new credentials" do
    preload_valid_credentials()
    assert Identity.refresh(force: true) == :ok
  end
end
