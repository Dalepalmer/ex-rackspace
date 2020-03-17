defmodule Rackspace.CloudFiles.DetailedObject do
  use Rackspace.Record

  @type t :: %__MODULE__{
          container: String.t(),
          name: String.t(),
          data: binary(),
          hash: String.t(),
          content_type: String.t(),
          content_encoding: String.t(),
          bytes: non_neg_integer(),
          last_modified: NaiveDateTime.t(),
          metadata: map()
        }

  record do
    field :container, :string
    field :name, :string
    field :data, :string
    field :hash, :string
    field :content_type, :string
    field :content_encoding, :string
    field :bytes, :integer
    # TODO: parse this to a naivedatetime (as long as it's consistent)
    field :last_modified, :string
    field :metadata, :map
  end

  def parse_meta(%Tesla.Env{headers: headers}) do
    headers
    |> Enum.filter(fn {key, _} ->
      String.starts_with?(key, "x-container-meta")
    end)
    |> Enum.map(fn {key, value} ->
      {String.slice(key, 17..-1), value}
    end)
    |> Enum.into(%{})
  end
end
