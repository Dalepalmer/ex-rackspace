defmodule Rackspace.Config do
  @me __MODULE__

  def start_link do
    config = Application.get_env(:rackspace, :api)
    username = config[:username] || System.get_env("RS_USERNAME")
    password = config[:password] || System.get_env("RS_PASSWORD")
    api_key = config[:api_key] || System.get_env("RS_API_KEY")

    Agent.start_link(
      fn ->
        %{
          username: username,
          password: password,
          api_key: api_key
        }
      end,
      name: @me
    )
  end

  def get, do: Agent.get(@me, & &1)

  def get(key), do: Agent.get(@me, &Map.get(&1, key))

  def set(%{} = changes), do: Agent.update(@me, &Map.merge(&1, changes))

  def set(key, value), do: Agent.update(@me, &Map.put(&1, key, value))
end
