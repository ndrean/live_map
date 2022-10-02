defmodule LiveMapWeb.MapLive do
  use Phoenix.LiveView, layout: {LiveMapWeb.LayoutView, "live.html"}
  alias LiveMapWeb.Presence
  alias LiveMapWeb.Endpoint
  require Logger

  @impl true
  def mount(_, %{"email" => email, "user_id" => user_id} = _session, socket) do
    if connected?(socket) do
      :ok = Endpoint.subscribe("event")
      :ok = Endpoint.subscribe("presence")
      {:ok, _} = Presence.track(self(), "presence", socket.id, %{user_id: user_id})
    end

    :ets.insert(:limit_user, {user_id, Time.utc_now()})

    {:ok,
     assign(socket,
       current: email,
       user_email: email,
       user_id: user_id,
       presence: Presence.list("presence") |> map_size
     )}
  end

  @impl true
  def render(assigns) do
    Logger.debug("Render LV ------------------")

    ~H"""
    <div>
      <p>Number connected user: <%= @presence %></p>
      <.live_component module={MapComp} id="map"  current={@current} user_id={@user_id}/>
    </div>
    """
  end

  #  phx-click from row in "new event table"
  @impl true
  def handle_event("delete_marker", %{"id" => id}, socket) do
    {:noreply, push_event(socket, "delete_marker", %{id: id})}
  end

  # handling the subscription to the topic sent by "date_picker"
  @impl true
  def handle_info(
        %{topic: "event", event: "new publication", payload: %{geojson: geojson}},
        socket
      ) do
    {:noreply, push_event(socket, "new pub", %{geojson: geojson})}
  end

  def handle_info(%{event: "presence_diff"}, socket) do
    nb_users = Presence.list("presence") |> map_size
    {:noreply, assign(socket, presence: nb_users)}
  end
end
