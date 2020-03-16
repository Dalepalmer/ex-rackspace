defmodule Rackspace do
  use Application
  import Supervisor.Spec

  @children [worker(Rackspace.Config, [])]
  @opts [strategy: :one_for_one, name: Rackspace.Supervisor]

  def start(_type, _args), do: Supervisor.start_link(@children, @opts)
end
