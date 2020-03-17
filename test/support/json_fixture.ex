defmodule Rackspace.Test.JsonFixture do
  import Tesla.Mock, only: [json: 2]

  @response_dir Path.expand("fixtures", __DIR__)

  def fixture(name, opts \\ []) do
    @response_dir
    |> Path.join(name)
    |> File.read!()
    |> Jason.decode!()
    |> json(opts)
  end
end
