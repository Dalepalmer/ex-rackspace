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

  @doc "Lists all available containers"
  @spec list() :: {:ok, [t()]} | {:error, Rackspace.Error.t()}
  def list do
    with {:ok, %{body: containers}} <- request_get("/") do
      {:ok, cast(containers)}
    end
  end

  @doc "Updates a container"
  @spec put(name :: String.t(), changes :: map()) ::
          {:ok, :updated} | {:error, Rackspace.Error.t()}
  def put(name, changes) do
    with {:ok, _} <- request_put(name, changes) do
      {:ok, :updated}
    end
  end

  @doc "Deletes a container"
  @spec delete(name :: String.t()) :: {:ok, :deleted} | {:error, Rackspace.Error.t()}
  def delete(name) do
    with {:ok, _} <- request_delete(name) do
      {:ok, :deleted}
    end
  end
end
