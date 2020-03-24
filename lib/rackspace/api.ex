defmodule Rackspace.Api do
  alias Rackspace.Config

  @raw_headers [{"user-agent", "ex-rackspace-v2"}]
  @headers @raw_headers ++
             [
               {"content-type", "application/json"},
               {"accept", "application/json"}
             ]
  def headers, do: @headers

  defmacro __using__(opts \\ []) do
    service = Keyword.fetch!(opts, :service)

    quote do
      defp base_url do
        Rackspace.Identity.refresh()

        region = Application.get_env(:rackspace, :default_region) || Config.get(:default_region)
        get_in(Config.get(:services), [unquote(service), region])
      end

      defp raw_client do
        Tesla.client([
          {Tesla.Middleware.BaseUrl, base_url()},
          {Tesla.Middleware.Headers, unquote(@raw_headers)},
          {Tesla.Middleware.Timeout, timeout: 15_000},
          Rackspace.Middleware.Auth
        ])
      end

      defp client do
        Tesla.client([
          {Tesla.Middleware.BaseUrl, base_url()},
          {Tesla.Middleware.Headers, unquote(@headers)},
          Rackspace.Middleware.Auth,
          Tesla.Middleware.JSON
        ])
      end

      defp request_get(url) do
        client()
        |> Tesla.get(url)
        |> handle_response()
      end

      defp request_get_raw(url) do
        raw_client()
        |> Tesla.get(url)
        |> handle_response()
      end

      defp request_post(url, body) do
        client()
        |> Tesla.post(url, body)
        |> handle_response()
      end

      defp request_put(url, body) do
        client()
        |> Tesla.put(url, body)
        |> handle_response()
      end

      defp request_put_raw(url, body) do
        raw_client()
        |> Tesla.put(url, body)
        |> handle_response()
      end

      defp request_delete(url) do
        client()
        |> Tesla.delete(url)
        |> handle_response()
      end

      defp handle_response({:ok, %Tesla.Env{status: status, body: body} = env})
           when status >= 200 and status < 300 do
        {:ok, %{body: body, env: env}}
      end

      defp handle_response({:ok, %Tesla.Env{status: 404}}) do
        {:error, %Rackspace.Error{code: 404, message: "resource not found"}}
      end

      defp handle_response({:ok, %Tesla.Env{status: status, body: body}}) do
        {:error, %Rackspace.Error{code: status, message: inspect(body)}}
      end

      defp handle_response({:error, reason}) do
        {:error, %Rackspace.Error{code: -1, message: inspect(reason)}}
      end
    end
  end
end
