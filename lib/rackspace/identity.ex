defmodule Rackspace.Identity do
  use Tesla, only: [:post]
  require Logger

  alias Rackspace.{Config, ConfigError, Api}

  plug Tesla.Middleware.BaseUrl, "https://identity.api.rackspacecloud.com/v2.0"
  plug Tesla.Middleware.Headers, Api.headers()
  plug Tesla.Middleware.JSON

  def refresh(opts \\ []) do
    force = Keyword.get(opts, :force, false)

    with true <- force || not valid?(),
         config <- Config.get(),
         credentials <- validate_auth!(config),
         body <- build_request(credentials),
         {:ok, %Tesla.Env{body: resp}} <- post("tokens", body) do
      Config.set(%{
        token: get_in(resp, ["access", "token", "id"]),
        expires_at: get_in(resp, ["access", "token", "expires"]),
        default_region: get_in(resp, ["access", "user", "RAX-AUTH:defaultRegion"]),
        services: resp |> get_in(["access", "serviceCatalog"]) |> build_services(),
        account: %{
          id: get_in(resp, ["access", "user", "id"]),
          name: get_in(resp, ["access", "user", "name"])
        }
      })

      :ok
    end
  end

  def valid? do
    not is_nil(Config.get(:token)) and not expired?()
  end

  def expired? do
    :expires_at
    |> Config.get()
    |> NaiveDateTime.from_iso8601!()
    |> NaiveDateTime.diff(NaiveDateTime.utc_now())
    |> Kernel.<(0)
  end

  defp build_request(%{username: username, api_key: api_key, password: nil}) do
    %{
      "auth" => %{
        "RAX-KSKEY:apiKeyCredentials" => %{
          "username" => username,
          "apiKey" => api_key
        }
      }
    }
  end

  defp build_request(%{username: username, password: password}) do
    %{
      "auth" => %{
        "passwordCredentials" => %{
          "username" => username,
          "password" => password
        }
      }
    }
  end

  defp build_services(service_descriptions) do
    for %{"name" => name, "endpoints" => endpoints} <- service_descriptions, into: %{} do
      region_map =
        Enum.reduce(endpoints, %{}, fn desc, acc ->
          Map.put(acc, desc["region"], desc["publicURL"])
        end)

      {Macro.underscore(name), region_map}
    end
  end

  defp validate_auth!(config) do
    safe =
      config
      |> Map.take([:username, :api_key, :password])
      |> Map.update!(:api_key, &redact/1)
      |> Map.update!(:password, &redact/1)

    Logger.debug("auth credentials: #{inspect(safe)}")

    if is_nil(config[:username]) do
      raise ConfigError, "username is required"
    end

    if is_nil(config[:password]) and is_nil(config[:api_key]) do
      raise ConfigError, "either password or api_key is required"
    end

    config
  end

  defp redact(nil), do: "(nil)"
  defp redact(_value), do: "*****"
end
