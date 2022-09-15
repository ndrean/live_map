defmodule LiveMapWeb.MapLive do
  use Phoenix.LiveView, layout: {LiveMapWeb.LayoutView, "live.html"}

  @impl true
  def mount(_, _, socket) do
    if connected?(socket), do: IO.inspect(socket)
    {:ok, assign(socket, place: nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <button id="push_marker" type="button" phx-click="push_marker" phx-value-lat={47.2} phx-value-lng={-1.7}>Add marker</button>
    <LMap.display />
    <Table.display place={@place}/>
    """
  end

  @impl true
  def handle_event("push_marker", %{"lat" => lat, "lng" => lng}, socket) do
    coords = [lat, lng]
    {:noreply, push_event(socket, "add", %{coords: coords})}
  end

  @impl true
  def handle_event("add_point", %{"place" => place}, socket) do
    {:noreply, assign(socket, :place, place)}
  end

  def handle_event("postgis", %{"eventsparams" => events_params}, socket) do
    IO.inspect(events_params)
    {:noreply, assign(socket, :events_params, events_params)}
  end

  def handle_event("delete_marker", %{"id" => id}, socket) do
    {:noreply, push_event(socket, "delete_marker", %{id: id})}
  end
end
