defmodule Rackspace.Api.Base do
  @moduledoc ~S"""
  Base module for service access. 
  
  It should be used as base module for any concrete implementation of specific service. 
  When used, in module you need to specify which service it is implmenting so some function may now
  how to read configuration received from rackspace. For instance, base_url(region) is using service keyword
  to find what is the base url for such service
  
  Possible services are:
  - `:autoscale`
  - `:cloud_servers_open_stack`
  - `:cloud_backup`
  - `:cloud_big_data`
  - `:cloud_block_storage`
  - `:cloud_databases`
  - `:cloud_dns`
  - `:cloud_feeds`
  - `:cloud_files`        
  - `:cloud_files_cdn`
  - `:cloud_images`
  - `:cloud_load_balancers`
  - `:cloud_metrics`
  - `:cloud_monitoring`
  - `:cloud_networks`
  - `:cloud_orchestration`
  - `:cloud_queues`
  - `:cloud_sites`
  - `:rack_cdn`
  - `:rackconnect`

  ## Examples
    ```elixir
    defmodule Rackspace.Api.CloudFiles.Container
      defstruct name: nil, count: 0, bytes: 0
      use Rackspace.Api.Base, service: :cloud_files

      def list([region: region]) do
        url = "#{base_url(region)}?format=json"
        # ... use url in HTTPotion
      end
    end
    ```
  """ 
  defmacro __using__([service: service]) do
    quote do
      import unquote(__MODULE__)
      require Logger

      defp base_url(region, opts \\ []) do
        Application.get_env(:rackspace, unquote(service))
          |> Keyword.get(:endpoints)
          |> Enum.find(fn(ep) -> String.downcase(ep["region"]) == String.downcase(region) end)
          |> Map.get("publicURL")
      end

      defp expired? do
        if expire_date = Rackspace.Config.get[:expires_at] do
          Timex.before?(Timex.parse!(expire_date, "{ISO:Extended}"), Timex.now)
        else
          false
        end
      end

      defp get_auth do
        auth = Rackspace.Config.get
        if auth[:token] == nil || expired?() do
          case Rackspace.Api.Identity.request do
            {:ok } -> 
              Rackspace.Config.get
            {:error, error } ->
              raise "fail to authenticate"
          end
        else
          Rackspace.Config.get
        end
      end

      defp validate_resp(resp) do
        case resp do
          %HTTPotion.Response{status_code: status_code} when status_code >= 200 and status_code <= 300 ->
            {:ok, resp}
          %HTTPotion.Response{} ->
            # validation and conflict errors in case 4XX errors and 500 should have empty body
            {:error, %Rackspace.Error{code: resp.status_code, message: resp.body}}
          %HTTPotion.ErrorResponse{message: message} ->
            {:error, %Rackspace.Error{code: 0, message: message}} 
        end
      end

      defp request_head(url, params \\ [], opts \\ []) do
        case get_auth() do
          %{token: token} when is_nil(token) == false ->
            timeout = Application.get_env(:rackspace, :timeout) || 5_000
            timeout = Keyword.get(opts, :timout, timeout)

            url
              |> query_params(params)
              |> HTTPotion.head([headers: [
                "X-Auth-Token": token,
              ], timeout: timeout])
          _ ->
            %Rackspace.Error{code: 0, message: "token_expired"}
        end
      end

      defp request_get(url, params \\ [], opts \\ []) do
        case get_auth() do
          %{token: token} when is_nil(token) == false ->
            timeout = Application.get_env(:rackspace, :timeout) || 5_000
            timeout = Keyword.get(opts, :timout, timeout)

            url
              |> query_params(params)
              |> HTTPotion.get([headers: [
                "X-Auth-Token": token,
                "Content-Type": "application/json"
              ], timeout: timeout])
          _ -> 
            %Rackspace.Error{code: 0, message: "token_expired"}
        end
      end

      defp request_post(url, body \\ <<>>, params \\ [], opts \\ []) do
        case get_auth() do
          %{token: token} when is_nil(token) == false ->
            timeout = Application.get_env(:rackspace, :timeout) || 5_000
            timeout = Keyword.get(opts, :timout, timeout)
            url
              |> query_params(params)
              |> HTTPotion.post([headers: [
                "X-Auth-Token": token
              ], body: body, timeout: timeout])
          _ -> 
            %Rackspace.Error{code: 0, message: "token_expired"}
        end      
      end

      defp request_put(url, body \\ <<>>, params \\ [], opts \\ []) do
        case get_auth() do
          %{token: token} when is_nil(token) == false ->
            timeout = Application.get_env(:rackspace, :timeout) || 5_000
            timeout = Keyword.get(opts, :timout, timeout)
            expire_at = Keyword.get(params, :expire_at, 63072000)
            url
              |> query_params(params)
              |> HTTPotion.put([headers: [
                "X-Auth-Token": token,
                "X-Delete-After": expire_at
              ], body: body, timeout: timeout])
          _ -> 
            %Rackspace.Error{code: 0, message: "token_expired"}
        end      
      end

      defp request_delete(url, params \\ [], opts \\ [], body \\ <<>>) do
        case get_auth() do
          %{token: token} when is_nil(token) == false ->
            content_type =  opts[:content_type] || "application/json"
            accept = opts[:accept] || "application/json"
            timeout = Application.get_env(:rackspace, :timeout) || 5_000
            timeout = Keyword.get(opts, :timout, timeout)
    
              url
                |> query_params(params)
                |> HTTPotion.delete([headers: [
                  "X-Auth-Token": token,
                  "Content-Type": content_type,
                  "Accept": accept
                ], body: body, timeout: timeout])
          _ -> 
            %Rackspace.Error{code: 0, message: "token_expired"}
        end
      end

      defp query_params(url, params) do
        Enum.reduce(params, url, fn({k,v}, acc) ->
          acc = "#{acc}&#{k}=#{v}"
        end)
      end

      defp get_temp_url_key(account_url) do
        temp_url_keys = Application.get_env(:rackspace, :temp_url_keys, %{})
        if Map.has_key?(temp_url_keys, account_url) do
          Map.get(temp_url_keys, account_url)
        else
          temp_url_key = request_head(account_url)[:headers]["x-account-meta-temp-url-key"]
          Application.put_env(:rackspace, :temp_url_keys, Map.put(temp_url_keys, account_url, temp_url_key))
          temp_url_key
        end
      end
    end
  end
end
