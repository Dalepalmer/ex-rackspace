defmodule Rackspace.CloudFiles.Object do
  @moduledoc """
  TODO: write docs
  """
  use Rackspace.Api, service: "cloud_files"
  use Rackspace.Record

  alias Rackspace.CloudFiles.DetailedObject

  @type t :: %__MODULE__{
          name: String.t(),
          hash: String.t(),
          content_type: String.t(),
          bytes: non_neg_integer(),
          last_modified: NaiveDateTime.t()
        }

  record do
    field :name, :string
    field :hash, :string
    field :content_type, :string
    field :bytes, :integer
    field :last_modified, :naive_datetime
  end

  @doc "Lists all available objects in a container"
  @spec list(container :: String.t()) ::
          {:ok, [t()]} | {:error, Rackspace.Error.t()}
  def list(container) do
    with {:ok, %{body: objects}} <- request_get(container) do
      {:ok, cast(objects)}
    end
  end

  @doc "Retrieves a single object from a container"
  @spec get(container :: String.t(), object :: String.t()) ::
          {:ok, DetailedObject.t()} | {:error, Rackspace.Error.t()}
  def get(container, object) do
    with {:ok, %{body: data, env: env}} <- request_get_raw(Path.join(container, object)) do
      params = %{
        "container" => container,
        "name" => object,
        "data" => data,
        "hash" => Tesla.get_header(env, "etag"),
        "content_type" => Tesla.get_header(env, "content-type"),
        "content_encoding" => Tesla.get_header(env, "content-encoding"),
        "bytes" => env |> Tesla.get_header("content-length") |> parse_int(),
        "last_modified" => Tesla.get_header(env, "last-modified"),
        "metadata" => DetailedObject.parse_meta(env)
      }

      {:ok, DetailedObject.cast(params)}
    end
  end

  @doc "Uploads an object to a container"
  @spec put(container :: String.t(), object :: String.t(), data :: binary()) ::
          {:ok, :created} | {:error, Rackspace.Error.t()}
  def put(container, object, data) do
    with {:ok, _} <- request_put_raw(Path.join(container, object), data) do
      {:ok, :created}
    end
  end

  @doc "Removes multiple objects from a container"
  @spec delete(
          container :: String.t(),
          object_or_objects :: String.t() | [String.t()]
        ) :: {:ok, :deleted} | {:ok, non_neg_integer()} | {:error, Rackspace.Error.t()}
  def delete(container, object_or_objects)

  # TODO: improve error handling
  def delete(container, objects) when is_list(objects) do
    Enum.each(objects, &delete(container, &1))

    {:ok, length(objects)}
  end

  def delete(container, object) do
    with {:ok, _} <- request_delete(Path.join(container, object)) do
      {:ok, :deleted}
    end
  end
end
