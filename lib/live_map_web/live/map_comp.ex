defmodule MapComp do
  use LiveMapWeb, :live_component
  require Logger

  @impl true
  def mount(socket) do
    Logger.debug("MOUNT MAP_____________________________")
    {:ok, assign(socket, place: nil, date: nil)}
  end

  @impl true
  def update(assigns, socket) do
    Logger.debug("UPDATE___________")
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(%{place: %{"coords" => coords}} = assigns) when not is_nil(coords) do
    Logger.debug("RENDER MAP_____________________________")
    assigns = assign(assigns, :coords, coords)

    ~H"""
    <div>
      <div id="map"
        phx-component={2}
        phx-hook="MapHook"
        phx-update="ignore">
        phx-target={@myself}
      </div>
      <LiveMapWeb.NewEventTable.display  user={@current} place={@place} date={@date} coords={@coords}/>
    </div>
    """
  end

  def render(assigns) do
    Logger.debug("RENDER MAP INIT_____________________________")

    ~H"""
    <div>
      <div id="map"
        phx-component={2}
        phx-hook="MapHook"
        phx-update="ignore">
        phx-target={@myself}
      </div>
      <LiveMapWeb.NewEventTable.display  user={@current} place={@place} date={@date}/>
    </div>
    """
  end

  # append the socket with a new market
  @impl true
  def handle_event("add_point", %{"place" => place}, socket) do
    {:noreply, assign(socket, :place, place)}
  end

  #  the "moveend" mutates proxy(movingmap) and subscribe triggers pushEvent
  @impl true
  def handle_event("postgis", %{"movingmap" => moving_map}, socket) do
    task =
      Task.Supervisor.async(LiveMap.EventSup, fn ->
        %{"distance" => distance, "center" => %{"lat" => lat, "lng" => lng}} = moving_map

        LiveMap.Repo.features_in_map(lng, lat, String.to_float(distance))
        |> List.flatten()
      end)

    results =
      case Task.await(task) do
        nil ->
          Logger.warn("Could not retrieve events")
          nil

        results ->
          results
      end

    {:noreply, push_event(socket, "update_map", %{data: results})}
  end
end
