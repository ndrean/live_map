defmodule LiveMapWeb.MapLive do
  use Phoenix.LiveView
  alias LiveMap.{Repo, User, Event}
  # alias LiveMap.{GeoUtils, GeoJSON}
  # , layout: {LiveMapWeb.LayoutView, "live.html"}

  @impl true
  def mount(_, %{"email" => email} = _session, socket) do
    LiveMapWeb.Endpoint.subscribe("event")
    socket = assign(socket, current: email)
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
    <.live_component module={MapComp} id="map"  current={@current}/>
    </div>
    """
  end

  #  phx-click from row in "new event table"
  @impl true
  def handle_event("delete_marker", %{"id" => id}, socket) do
    {:noreply, push_event(socket, "delete_marker", %{id: id})}
  end

  #  phx-click from "new event table"
  def handle_event("save_event", %{"place" => place}, socket) do
    # %{"coords" => places, "distance" => distance}},
    # [
    # %{"lat" => lat1, "lng" => lng1, "name" => ad1},
    # %{"lat" => lat2, "lng" => lng2, "name" => ad2}
    # ] = places

    date = Date.utc_today()
    owner_id = Repo.get_by(User, email: socket.assigns.current).id

    geojson = Event.save_geojson(place, owner_id, date)
    LiveMapWeb.Endpoint.broadcast!("event", "emmit_event", %{geojson: geojson})

    # NOT WORKING !!!!!
    socket |> put_flash(:info, "Your new event has been saved")
    {:noreply, push_event(socket, "clear_event", %{})}
  end

  # def handle_info(%{data: data}, socket) do
  #   IO.puts("info_____________________________")
  #   {:noreply, push_event(socket, "init", %{data: data})}
  # end
end
