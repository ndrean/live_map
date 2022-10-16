defmodule LiveMapWeb.MapLive do
  # use Phoenix.LiveView, layout: {LiveMapWeb.LayoutView, "live.html"}
  use LiveMapWeb, :live_view
  alias LiveMapWeb.Presence
  alias LiveMapWeb.Endpoint
  alias LiveMapWeb.{SelectedEvents, MapComp, QueryPicker}
  # alias LiveMapWeb.MailController
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
       selected: nil,
       page: 1,
       temporary_assigns: [events: []]
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
    <p>Number connected user: <%= @presence %></p>
    <.live_component module={MapComp} id="map"  current={@current} user_id={@user_id}/>
    <.live_component module={QueryPicker} id="query_picker" user={@current} user_id={@user_id} coords={@coords}/>
    <.live_component module={SelectedEvents} id="selected" selected={@selected} page={@page} user_id={@user_id} user={@current}/>
    </div>
    """
  end

  #  phx-click from row in "new event table"
  @impl true
  def handle_event("delete_marker", %{"id" => id}, socket) do
    id = if is_binary(id), do: String.to_integer(id)
    {:noreply, push_event(socket, "delete_marker", %{id: id})}
  end

  def handle_event("delete_event", %{"id" => id, "owner" => _owner}, socket) do
    id = if is_binary(id), do: String.to_integer(id)

    LiveMap.Event.delete_event(id)
    {:noreply, put_flash(socket, :info, "really wanna delete it?")}
    # end
  end

  @impl true
  #  remove all highlights in Leaflet since checkboxes defaults to false on refresh (no more sync)
  def handle_info({:down_check_all}, socket) do
    {:noreply, push_event(socket, "toggle_all_down", %{})}
  end

  # broadcast new event to all users from the date_picker form
  @impl true
  def handle_info(
        %{topic: "event", event: "new event", payload: %{geojson: geojson}},
        socket
      ) do
    {:noreply, push_event(socket, "new pub", %{geojson: geojson})}
  end

  def handle_info(%{event: "presence_diff"}, socket) do
    nb_users = Presence.list("presence") |> map_size
    {:noreply, assign(socket, presence: nb_users)}
  end

  # update the assigns with new map coords for QueryPicker to be able to query the area
  def handle_info({:map_coords, map_coords}, socket) do
    {:noreply, assign(socket, :coords, map_coords)}
  end

  # callback from query-picker form: we build the records for the table
  # we need to transform a record from [id, map_owner, map_pending || map_confirmed, date]
  # to [id, map_owner, map_pending, map_confirmed, date]
  def handle_info({:selected_events, payload}, socket) do
    payload =
      payload
      |> Enum.map(fn [id, users, date] = _event ->
        users = users |> Map.keys() |> set_all_keys(users)
        [id, users, date]
      end)

    # update the child table
    send_update(SelectedEvents, id: "selected", selected: payload)

    # socket =
    #   socket
    #   |> assign(:selected, payload)
    #   |> assign(page: socket.assigns.page + 1)

    {:noreply, socket}
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

      true ->
        users
    end
  end
end
