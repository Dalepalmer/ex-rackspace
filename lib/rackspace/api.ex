defmodule Rackspace.Api do
  alias Rackspace.Config

  @headers [
    {"user-agent", "ex-rackspace-v2"},
    {"content-type", "application/json"},
    {"accept", "application/json"}
  ]
  def headers, do: @headers

  defmacro __using__(opts \\ []) do
    service = Keyword.fetch!(opts, :service)

    quote do
      defp client do
        Rackspace.Identity.refresh()

        region = Application.get_env(:rackspace, :default_region) || Config.get(:default_region)
        base_url = get_in(Config.get(:services), [unquote(service), region])

        middleware = [
          {Tesla.Middleware.BaseUrl, base_url},
          {Tesla.Middleware.Headers, unquote(headers())},
          Rackspace.Middleware.Auth,
          Tesla.Middleware.JSON
        ]

        Tesla.client(middleware)
      end

      defp request_get(url, opts \\ []) do
        client()
        |> Tesla.get(url, opts)
        |> handle_response()
      end

      defp request_post(url, body, opts \\ []) do
        client()
        |> Tesla.post(url, body, opts)
        |> handle_response()
      end

      defp request_put(url, body, opts \\ []) do
        client()
        |> Tesla.put(url, body, opts)
        |> handle_response()
      end

      defp request_delete(url, opts \\ []) do
        client()
        |> Tesla.delete(url, opts)
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
