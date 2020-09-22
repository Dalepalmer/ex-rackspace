defmodule Rackspace.Api.CloudFiles.Object do
  defstruct [
    container: nil,
    bytes: 0,
    content_type: nil,
    content_encoding: nil,
    hash: nil,
    last_modified: nil,
    name: nil,
    metadata: [],
    data: <<>>
  ]

  require Logger
  use Rackspace.Api.Base, service: :cloud_files

  def list(container, opts \\ []) do
    get_auth()
    region = opts[:region] || Application.get_env(:rackspace, :default_region)
    url = "#{base_url(region)}/#{container}?format=json"
    resp = request_get(url, opts)
    case validate_resp(resp) do
      {:ok, _} ->
        resp
          |> Map.get(:body)
          |> Poison.decode!(keys: :atoms)
          |> Enum.reduce([], fn(object, acc)->
            [%__MODULE__{
              container: container,
              name: object.name,
              bytes: object.bytes,
              content_type: object.content_type
            } | acc]
          end)
      {:error, error} -> error
    end
  end

  def get(container, object, opts \\ []) do
    get_auth()
    region = opts[:region] || Application.get_env(:rackspace, :default_region)
    url = "#{base_url(region)}/#{container}/#{object}?format=json"
    resp = request_get(url, opts)
    case validate_resp(resp) do
      {:ok, _} ->
        headers = resp.headers.hdrs
        metadata = Enum.filter(headers, fn({k,_v}) ->
          to_string(k)
            |> String.starts_with?("x-container-meta")
        end)
        {bytes, _} = Integer.parse(headers["content-length"])

        %__MODULE__{
          container: container,
          name: object,
          data: resp.body,
          hash: headers["etag"],
          content_type: headers["content-type"],
          content_encoding: headers["content-encoding"],
          bytes: bytes,
          last_modified: headers["last-modified"],
          metadata: metadata
        }
      {:error, error} -> error
    end
  end

  @doc """
  Get a public temporary URL for an object.

  `opts` can contain:
    - `method`: "GET" to return the file.
    - `seconds`: How many seconds this URL should be valid.
    - `expires`: The exact unix time to expire, in seconds.
    - `region`: The file region.
    - `filename`: Sets the `Content-Disposition` header for the returned file.
    - `inline`: Sets `Content-Disposition` to `inline` so the file won't be downloaded.

  @see https://docs.rackspace.com/docs/cloud-files/v1/use-cases/public-access-to-your-cloud-files-account/
  """
  def temp_url(container, object, opts \\ []) do
    get_auth()
    method = Keyword.get(opts, :method, "GET")
    seconds = Keyword.get(opts, :seconds, 3600)
    expires = Keyword.get(opts, :expires, DateTime.to_unix(DateTime.utc_now()) + seconds)
    region = Keyword.get(opts, :region, Application.get_env(:rackspace, :default_region))

    account_url = base_url(region)
    full_url = "#{account_url}/#{container}/#{object}"
    full_path = full_url |> URI.parse() |> Map.get(:path)
    hmac_body = "#{String.upcase(method)}\n#{expires}\n#{full_path}"
    signature = :crypto.mac(:hmac, :sha256, get_temp_url_key(account_url), hmac_body) |> Base.encode16(case: :lower)

    query = 
      opts
      |> Keyword.drop([:method, :seconds, :expires, :region])
      |> Keyword.put(:temp_url_sig, signature)
      |> Keyword.put(:temp_url_expires, expires)

    "#{full_url}#{query_params("?", query)}"
  end

  def put(container, name, data, opts \\ []) do
    get_auth()
    region = opts[:region] || Application.get_env(:rackspace, :default_region)
    url = "#{base_url(region)}/#{container}/#{name}?format=json"
    resp = request_put(url, data, opts)
    case validate_resp(resp) do
      {:ok, _} -> {:ok, :created}
      {:error, error} -> error
    end
  end

  def delete(container, object, opts \\ []) do
    get_auth()
    region = opts[:region] || Application.get_env(:rackspace, :default_region)
    url = "#{base_url(region)}/#{container}/#{object}?format=json"
    resp = request_delete(url)
    case validate_resp(resp) do
      {:ok, _} -> {:ok, :deleted}
      {:error, error} -> error
    end
  end

  def delete_multiple_objects(container, objects, opts \\ []) do
    get_auth()
    region = opts[:region] || Application.get_env(:rackspace, :default_region)
    body = objects |> Enum.map(fn(obj) -> URI.encode("#{container}/#{obj}") end) |> Enum.join("\n")
    url = "#{base_url(region)}?format=json&bulk-delete=true"
    resp = request_delete(url, [], %{content_type: "text/plain"}, body)
    case validate_resp(resp) do
      {:ok, _} ->
        case Poison.decode(resp.body) do
          {:ok, body} -> {:ok, body["Number Deleted"]}
          {_, error} -> {:error, error}
        end
      {:error, error} -> error
    end
  end
end
