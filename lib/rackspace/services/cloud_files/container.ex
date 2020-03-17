defmodule Rackspace.CloudFiles.Container do
  @moduledoc """
  TODO: write docs
  """
  use Rackspace.Api, service: "cloud_files"
  use Rackspace.Record

  @type t :: %__MODULE__{
          bytes: non_neg_integer(),
          count: non_neg_integer(),
          name: String.t()
        }

  record do
    field :bytes, :integer
    field :count, :integer
    field :name, :string
  end

  # TODO: type `opt`
  @type opt :: any()
  @type options :: [opt]

  @doc "Lists all available containers"
  @spec list(opts :: options()) :: {:ok, [t()]} | {:error, Rackspace.Error.t()}
  def list(opts \\ []) do
    with {:ok, %{body: containers}} <- request_get("/", opts) do
      {:ok, cast(containers)}
    end
  end

  @doc "Updates a container"
  @spec put(name :: String.t(), opts :: options()) ::
          {:ok, :updated} | {:error, Rackspace.Error.t()}
  def put(name, opts \\ []) do
    with {:ok, _} <- request_put(name, opts) do
      {:ok, :updated}
    end
  end

  @doc "Deletes a container"
  @spec delete(name :: String.t(), opts :: options()) ::
          {:ok, :deleted} | {:error, Rackspace.Error.t()}
  def delete(name, opts \\ []) do
    with {:ok, _} <- request_delete(name, opts) do
      {:ok, :deleted}
    end
  end
end
