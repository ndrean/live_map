defmodule LiveMapWeb.MapLive do
  use LiveMapWeb, :live_view
  # use Phoenix.LiveView
  # , layout: {LiveMapWeb.LayoutView, "live.html"}

  @impl true
  def mount(_, %{"email" => email} = _session, socket) do
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

  # <UpdateBtnComponent.display />
  # <LiveMapWeb.NewEventTable.display place={@place} user={@current}/>

  # <LMap.display />

  # <button type="button" phx-click="push_marker" phx-value-lat={47.2} phx-value-lng={-1.7}>Add marker</button>

  # the "UpdateBtnComponent" is stateless, thus the parent LiveView holds the "handle_event"
  # @impl true
  # def handle_event("push_marker", %{"lat" => lat, "lng" => lng}, socket) do
  #   coords = [lat, lng]
  #   {:noreply, push_event(socket, "add", %{coords: coords})}
  # end

  @impl true
  def handle_event("delete_marker", %{"id" => id}, socket) do
    IO.inspect(id, label: "delete")
    {:noreply, push_event(socket, "delete_marker", %{id: id})}
  end

  @impl true
  def handle_info(%{new_event: new_event}, socket) do
    IO.inspect(new_event, label: "in parent LiveView ********************************")
    {:noreply, socket}
  end

  def handle_info(%{data: data}, socket) do
    IO.puts("info_____________________________")
    {:noreply, push_event(socket, "init", %{data: data})}
  end
end
