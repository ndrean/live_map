defmodule MapComp do
  use LiveMapWeb, :live_component
  # use Phoenix.LiveComponent

  @path "./lib/live_map_web/live/data.json"

  @impl true
  def mount(socket) do
    IO.puts("MOUNT MAP_____________________________")
    {:ok, assign(socket, place: nil)}
  end

  @impl true
  def update(assigns, socket) do
    IO.puts("UPDATE MAP_____________________________")

    with {:ok, body} <- File.read(@path),
         {:ok, data} <- Jason.decode(body) do
      IO.puts("SEND=================")
      send(self(), %{data: data})
      {:ok, assign(socket, assigns)}
    end
  end

  @impl true
  def render(assigns) do
    IO.puts("RENDER MAP_____________________________")

    ~H"""
    <div>
    <div id="map"
    phx-component={2}
    phx-hook="MapHook"
    phx-update="ignore">
    phx-target={@myself}
    </div>
    <LiveMapWeb.NewEventTable.render  user={@current} place={@place}/>

    </div>
    """
  end

  @impl true
  def handle_event("add_point", %{"place" => place}, socket) do
    {:noreply, assign(socket, :place, place)}
  end

  @impl true
  def handle_event("postgis", %{"eventsparams" => events_params}, socket) do
    IO.inspect(events_params, label: "POSTGIS=============================")
    {:noreply, assign(socket, :events_params, events_params)}
  end

  def handle_event("new_event", %{"newEvent" => new_event}, socket) do
    send(self(), %{new_event: new_event})
    {:noreply, assign(socket, :new_event, new_event)}
  end
end
