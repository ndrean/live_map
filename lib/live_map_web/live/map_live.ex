defmodule LiveMapWeb.MapLive do
  use Phoenix.LiveView, layout: {LiveMapWeb.LayoutView, "live.html"}
  alias LiveMap.Event

  @impl true
  def mount(_, %{"email" => email, "user_id" => user_id} = _session, socket) do
    if connected?(socket), do: LiveMapWeb.Endpoint.subscribe("event")

    {:ok, assign(socket, current: email, user_id: user_id)}
  end

  @impl true
  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    IO.puts("Render LV ------------------")

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

  # phx-submit from form in new event table
  def handle_info({:newintown, %{"place" => place, "date" => date}}, socket) do
    IO.puts("SAVE EVENT ----------------------")

    owner_id = socket.assigns.user_id

    Task.Supervisor.async_nolink(LiveMap.TSup, fn ->
      Event.save_geojson(place, owner_id, date)
    end)
    |> Task.await()
    |> then(fn geojson ->
      LiveMapWeb.Endpoint.broadcast!("event", "new publication", %{geojson: geojson})
    end)

    {:noreply, put_flash(socket, :info, "Event saved")}
  end

  # handler of the subscription to the topic
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
