defmodule LiveMap.Application do
  @moduledoc false

  use Application

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
      LiveMapWeb.Endpoint,
      LiveMapWeb.Presence,
      {Registry, [keys: :unique, name: Registry.SessionRegistry]},
      {Task.Supervisor, name: LiveMap.EventSup},
      {Task.Supervisor, name: LiveMap.AsyncMailSup}
    ]

    # :ets.new(:limit_user, [:set, :named_table, :public])
    opts = [strategy: :one_for_one, name: LiveMap.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LiveMapWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
