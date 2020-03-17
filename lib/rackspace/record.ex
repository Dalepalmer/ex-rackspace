defmodule Rackspace.Record do
  @moduledoc """
  This module is a loose combination of `:typed_struct` and `:ecto` - it exposes
  the `record` macro which allows for the definition of structs that come with
  a `&cast/2` method that will take a string-keyed map and automatically pull out
  corresponding keys and parse their values with the corresponding type's parser.
  """
  defmacro __using__(_opts) do
    quote do
      import Rackspace.Record, only: [record: 1]
    end
  end

  defmacro record(block) do
    quote do
      Module.register_attribute(__MODULE__, :fields, accumulate: true)
      Module.register_attribute(__MODULE__, :types, accumulate: true)

      import Rackspace.Record
      unquote(block)

      defstruct @fields

      def __keys__, do: @fields |> Keyword.keys() |> Enum.reverse()
      def __defaults__, do: Enum.reverse(@fields)
      def __types__, do: Enum.reverse(@types)

      def cast(param_list) when is_list(param_list) do
        Enum.map(param_list, &cast/1)
      end

      def cast(base \\ %__MODULE__{}, %{} = params) do
        types = __types__()

        Enum.reduce(__defaults__(), base, fn {key, default}, base ->
          raw = Map.get(params, to_string(key), default)
          parsed = Rackspace.Record.parse(raw, Keyword.get(types, key))
          Map.put(base, key, parsed)
        end)
      end
    end
  end

  defmacro field(name, type, opts \\ []) do
    quote do
      Rackspace.Record.__field__(
        __MODULE__,
        unquote(name),
        unquote(type),
        unquote(opts)
      )
    end
  end

  def __field__(mod, name, type, opts) when is_atom(name) do
    if mod |> Module.get_attribute(:fields) |> Keyword.has_key?(name) do
      raise ArgumentError, "the field #{inspect(name)} is already set"
    end

    default = opts[:default]

    Module.put_attribute(mod, :fields, {name, default})
    Module.put_attribute(mod, :types, {name, type})
  end

  def __field__(_mod, name, _type, _opts) do
    raise ArgumentError, "a field name must be an atom, got #{inspect(name)}"
  end

  def parse(nil, _type), do: nil

  def parse(raw, :integer) when is_integer(raw), do: raw
  def parse(raw, :integer) when is_binary(raw), do: parse_int(raw)

  def parse(raw, :string) when is_integer(raw), do: to_string(raw)
  def parse(raw, :string) when is_binary(raw), do: raw

  def parse(raw, :naive_datetime) when is_binary(raw), do: NaiveDateTime.from_iso8601!(raw)

  def parse(raw, :map) when is_binary(raw), do: Jason.decode!(raw)
  def parse(raw, :map) when is_map(raw), do: raw

  def parse_int(str) when is_binary(str) do
    {int, _} = Integer.parse(str)
    int
  end
end
