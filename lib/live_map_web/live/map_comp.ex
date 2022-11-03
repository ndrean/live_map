defmodule LiveMapWeb.MapComp do
  use LiveMapWeb, :live_component
  alias LiveMap.Repo
  alias LiveMapWeb.NewEventTable
  require Logger

  @impl true
  def mount(socket) do
    {:ok, assign(socket, place: nil, date: nil)}
  end

  @impl true
  def update(assigns, socket) do
    IO.puts("update map")
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(%{place: %{"coords" => coords}} = assigns) when not is_nil(coords) do
    IO.inspect(assigns.flash)

    ~H"""
    <div>
      <div id="map"
        phx-component={2}
        phx-hook="MapHook"
        phx-update="ignore"
        phx-target={@myself}
      >
      </div>
      <NewEventTable.display  user_id={@user_id} user={@current} place={@place} date={@date}/>
    </div>
    """
  end

  # render map init
  def render(assigns) do
    ~H"""
    <div>
      <div id="map"
        phx-component={2}
        phx-hook="MapHook"
        phx-update="ignore"
        phx-target={@myself}
      >
      </div>
      <NewEventTable.display  user={@current} place={@place} date={@date}/>
    </div>
    """
  end

  # append the socket with a new marker to add a new record in the table
  @impl true
  def handle_event("add_point", %{"place" => place}, socket) do
    {:noreply, assign(socket, :place, place)}
  end

  #  we detected the map was moved, so the with new coords, we query the local events
  @impl true
  def handle_event("postgis", %{"movingmap" => moving_map}, socket) do
    # send new map coords once detected for the query table
    %{"distance" => distance, "center" => %{"lat" => lat, "lng" => lng}} = moving_map

    case Repo.features_in_map(lng, lat, String.to_float(distance)) do
      {:error, message} ->
        send(self(), {:flash_postgis, message})
        {:noreply, socket}

      {:ok, rows} ->
        send(self(), {:map_coords, moving_map})
        {:noreply, push_event(socket, "update_map", %{data: List.flatten(rows)})}
    end
  end
end
