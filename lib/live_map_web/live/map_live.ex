defmodule LiveMapWeb.MapLive do
  use Phoenix.LiveView, layout: {LiveMapWeb.LayoutView, "live.html"}
  alias LiveMap.Event
  require Logger

  @impl true
  def mount(_, %{"email" => email, "user_id" => user_id} = _session, socket) do
    if connected?(socket), do: :ok = LiveMapWeb.Endpoint.subscribe("event")
    {:ok, assign(socket, current: email, user_id: user_id)}
  end

  @impl true
  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    Logger.debug("Render LV ------------------")

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

  defp handle_geojson(%LiveMap.GeoJSON{} = geojson, socket) do
    :ok = LiveMapWeb.Endpoint.broadcast!("event", "new publication", %{geojson: geojson})
    {:noreply, put_flash(socket, :info, "Event saved")}
  end

  defp handle_geojson({:error, _reason}, socket),
    do: {:noreply, put_flash(socket, :error, "Internal error")}

  # phx-submit from form in new event table
  def handle_info({:newintown, %{"place" => place, "date" => date}}, socket) do
    owner_id = socket.assigns.user_id

    Task.Supervisor.async_nolink(LiveMap.EventSup, fn ->
      Event.save_geojson(place, owner_id, date)
    end)
    |> Task.await()
    |> then(fn geojson -> handle_geojson(geojson, socket) end)
  end

  # handling the subscription to the topic
  @impl true
  def handle_info(
        %Phoenix.Socket.Broadcast{
          topic: "event",
          event: "new publication",
          payload: %{geojson: geojson}
        },
        socket
      ) do
    {:noreply, push_event(socket, "new pub", %{geojson: geojson})}
  end
end
