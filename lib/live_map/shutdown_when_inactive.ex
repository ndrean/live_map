defmodule ShutdownWhenInactive do
  use Task
  require Logger

  @moduledoc """
  See   # https://fly.io/phoenix-files/shut-down-idle-phoenix-app/
  and https://hexdocs.pm/elixir/Task.html#module-statically-supervised-tasks
  """

  def start_link(arg) do
    Task.start_link(__MODULE__, :run, [arg])
  end

  def run(arg) do
    Logger.info("Start inactivity watching process ---------------")
    Process.sleep(arg)

    if :ranch.procs(LiveMapWeb.Endpoint.HTTP, :connections) == [] do
      Logger.info("------------Shut down...")
      System.stop(0)
    else
      run(arg)
    end
  end
end
