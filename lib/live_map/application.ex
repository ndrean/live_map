defmodule LiveMap.Application do
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      LiveMap.Repo,
      LiveMap.ChatCache,
      # Start the Telemetry supervisor
      LiveMapWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: LiveMap.PubSub},
      # Start the Endpoint (http/https)
      LiveMapWeb.Presence,
      # {Registry, [keys: :unique, name: Registry.SessionRegistry]},
      LiveMapWeb.Endpoint,
      {Task, fn -> shutdown_when_inactive(:timer.minutes(5)) end},
      {Task.Supervisor, name: LiveMap.EventSup},
      {Task.Supervisor, name: LiveMap.AsyncMailSup}
    ]

    opts = [strategy: :one_for_one, name: LiveMap.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # https://fly.io/phoenix-files/shut-down-idle-phoenix-app/
  defp shutdown_when_inactive(every_ms) do
    Logger.info("start inactivity watching process ---------------")
    Process.sleep(every_ms)

    if :ranch.procs(LiveMapWeb.Endpoint.HTTP, :connections) == [] do
      Logger.info("------------Shut down...")
      System.stop(0)
    else
      shutdown_when_inactive(every_ms)
    end
  end

  # Tell Phoenix to update the endpoint configuration whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LiveMapWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
