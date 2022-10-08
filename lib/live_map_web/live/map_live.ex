defmodule LiveMapWeb.MapLive do
  use Phoenix.LiveView, layout: {LiveMapWeb.LayoutView, "live.html"}
  alias LiveMapWeb.Presence
  alias LiveMapWeb.Endpoint
  alias LiveMapWeb.{SelectedEvents, MapComp, QueryPicker}
  alias LiveMapWeb.MailController
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
       presence: Presence.list("presence") |> map_size,
       coords: %{},
       selected: nil
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
    <p>Number connected user: <%= @presence %></p>
    <.live_component module={MapComp} id="map"  current={@current} user_id={@user_id}/>
    <.live_component module={QueryPicker} id="query_picker" current={@current} user_id={@user_id} coords={@coords}/>
    <.live_component module={SelectedEvents} id="selected" selected={@selected} user_id={@user_id} user={@current}/>
    </div>
    """
  end

  #  phx-click from row in "new event table"
  @impl true
  def handle_event("delete_marker", %{"id" => id}, socket) do
    {:noreply, push_event(socket, "delete_marker", %{id: id})}
  end

  def handle_event("delete_event", %{"id" => id, "owner" => _owner}, socket) do
    LiveMap.Event.delete_event(id)
    {:noreply, put_flash(socket, :info, "really wanna delete it?")}
    # end
  end

  def handle_event("send_demand", %{"event-id" => event_id, "user-id" => user_id}, socket) do
    MailController.create_demand(%{event_id: String.to_integer(event_id), user_id: user_id})
    {:noreply, socket}
  end

  # highlight the event in Leaflet.js when checkbox is ticked in table events
  def handle_event("checkbox", %{"id" => id, "value" => "on"}, socket) do
    {:noreply, push_event(socket, "toggle_up", %{id: id})}
  end

  # remove the highlight when checkbox toggled off in table events
  def handle_event("checkbox", %{"id" => id}, socket) do
    {:noreply, push_event(socket, "toggle_down", %{id: id})}
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

  def handle_info({:map_coords, map_coords}, socket) do
    {:noreply, assign(socket, :coords, map_coords)}
  end

  def handle_info({:selected_events, payload}, socket) do
    payload =
      payload
      |> Enum.map(fn [id, users, date] = _event ->
        users = users |> Map.keys() |> set_all_keys(users)
        [id, users, date]
      end)

    {:noreply, assign(socket, :selected, payload)}
  end

  defp set_all_keys(keys, users) do
    cond do
      "pending" not in keys and "confirmed" not in keys ->
        users
        |> Map.merge(%{"pending" => []})
        |> Map.merge(%{"confirmed" => []})

      "pending" not in keys ->
        Map.merge(users, %{"pending" => []})

      "confirmed" not in keys ->
        Map.merge(users, %{"confirmed" => []})
    end
  end
end
