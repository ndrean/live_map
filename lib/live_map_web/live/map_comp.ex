defmodule MapComp do
  # use LiveMapWeb, :live_component
  use Phoenix.LiveComponent

  @impl true
  def mount(socket) do
    IO.puts("MOUNT MAP_____________________________")
    {:ok, assign(socket, place: nil)}
  end

  @impl true
  def update(assigns, socket) do
    IO.puts("UPDATE MAP_____________________________")

    # IO.inspect(assigns.events_params, label: "UPDATE_________________")

    # @path "./lib/live_map_web/live/data.json"
    # with {:ok, body} <- File.read(@path),
    #      {:ok, data} <- Jason.decode(body) do
    #   IO.puts("SEND=================")

    #   send(self(), %{data: data})
    # {:ok, assign(socket, assigns)}
    # end
    {:ok, assign(socket, assigns)}
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
      <LiveMapWeb.NewEventTable.display  user={@current} place={@place}/>
    </div>
    """
  end

  @impl true
  def handle_event("add_point", %{"place" => place}, socket) do
    {:noreply, assign(socket, :place, place)}
  end

  #  the "moveend" mutates proxy(movingmap) and subscribe triggers pushEvent
  @impl true
  def handle_event("postgis", %{"movingmap" => moving_map}, socket) do
    IO.puts("POSTGIS------------------------")
    %{"distance" => distance, "center" => %{"lat" => lat, "lng" => lng}} = moving_map
    results = List.flatten(LiveMap.Repo.features_in_map(lng, lat, String.to_float(distance)))

    {:noreply, push_event(socket, "update_map", %{data: results})}
  end

  # new marker -> update local socket for table
  @impl true
  def handle_event("new_event", %{"newEvent" => new_event}, socket) do
    send(self(), %{new_event: new_event})
    {:noreply, assign(socket, :new_event, new_event)}
  end
end
