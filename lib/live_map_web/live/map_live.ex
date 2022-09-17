defmodule LiveMapWeb.MapLive do
  use LiveMapWeb, :live_view
  # use Phoenix.LiveView
  # , layout: {LiveMapWeb.LayoutView, "live.html"}

  @impl true
  def mount(_, %{"email" => email} = _session, socket) do
    socket = assign(socket, current: email, place: nil, eventsparams: nil)
    IO.inspect(self(), label: "Mount parent -------")
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    IO.inspect(self(), label: "Render Parent ***************************")

    ~H"""
    <div>
    <UpdateBtnComponent.display />
    <.live_component module={MapComp} id="map" {assigns}/>
    <LiveMapWeb.NewEventTable.display place={@place} user={@current}/>
    </div>
    """
  end

  # <LMap.display />

  # <button type="button" phx-click="push_marker" phx-value-lat={47.2} phx-value-lng={-1.7}>Add marker</button>

  # the "UpdateBtnComponent" is stateless, thus the parent LiveView holds the "handle_event"
  @impl true
  def handle_event("push_marker", %{"lat" => lat, "lng" => lng}, socket) do
    coords = [lat, lng]
    {:noreply, push_event(socket, "add", %{coords: coords})}
  end

  # @impl true
  # def handle_event("add_point", %{"place" => place}, socket) do
  #   IO.puts("LV-add_point")
  #   {:noreply, assign(socket, :place, place)}
  # end

  # def handle_event("postgis", %{"eventsparams" => events_params}, socket) do
  #   IO.puts("LV-postgis")
  #   {:noreply, assign(socket, :events_params, events_params)}
  # end

  # def handle_event("delete_marker", %{"id" => id}, socket) do
  #   {:noreply, push_event(socket, "delete_marker", %{id: id})}
  # end
end
