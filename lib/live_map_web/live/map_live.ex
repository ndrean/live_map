defmodule LiveMapWeb.MapLive do
  use LiveMapWeb, :live_view
  alias LiveMapWeb.Presence
  alias LiveMapWeb.Endpoint
  alias LiveMapWeb.{SelectedEvents, MapComp, QueryPicker, HeaderSection}
  require Logger
  import LiveMap.Utils, only: [safely_use: 1]

  # @menu ~w(a b c) <- test
  @impl true
  def mount(_, %{"email" => email, "user_id" => user_id} = _session, socket) do
    if connected?(socket) do
      :ok = Endpoint.subscribe("event")
      :ok = Endpoint.subscribe("presence")
      {:ok, _} = Presence.track(self(), "presence", socket.id, %{user_id: user_id})
    end

    # :ets.insert(:limit_user, {user_id, Time.utc_now()})

    {:ok,
     assign(socket,
       id: socket.id,
       current: email,
       user_email: email,
       user_id: user_id,
       presence: Presence.list("presence") |> map_size,
       coords: %{},
       selected: nil,
       temporary_assigns: [events: []]
       # , presences: %{}]
     )}
  end

  # def update(assigns) do
  # end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :presence, assigns.presence)

    ~H"""
    <div id="live">
      <HeaderSection.display presence={@presence} />
      <.live_component module={MapComp} id="map"
        user={@current} user_id={@user_id} coords={@coords}
      />
      <.live_component module={QueryPicker} id="query_picker"
        user={@current} user_id={@user_id} coords={@coords}
      />
      <.live_component module={SelectedEvents} id="selected"
        selected={@selected} user_id={@user_id} user={@current}

      />
    </div>
    """
  end

  #  backend delete of marker: phx-click from row in "new event table"
  @impl true
  def handle_event("delete_marker", %{"id" => id}, socket) do
    {:noreply, push_event(socket, "delete_marker", %{id: safely_use(id)})}
  end

  @impl true
  # update all the maps when an event is deleted
  def handle_info(%{topic: "event", event: "delete_event", payload: %{id: id}}, socket) do
    {:noreply, push_event(socket, "delete_event", %{id: id})}
  end

  #  remove all highlights in Leaflet since checkboxes defaults to false on refresh (no more sync)
  def handle_info({:down_check_all}, socket) do
    {:noreply, push_event(socket, "toggle_all_down", %{})}
  end

  # broadcast new event to all users from the date_picker form
  @impl true
  def handle_info(
        %{topic: "event", event: "new_event", payload: %{geojson: geojson}},
        socket
      ) do
    {:noreply, push_event(socket, "new_pub", %{geojson: geojson})}
  end

  # example of error: bad user_id
  def handle_info("flash_error", socket) do
    {:noreply, put_flash(socket, :error, "Event not saved due to error")}
  end

  def handle_info("flash_update", socket) do
    {:noreply, put_flash(socket, :error, "Update error")}
  end

  def handle_info({:push_flash, from, message}, socket) do
    {:noreply, put_flash(socket, :error, inspect("#{inspect(from)}: #{inspect(message)}"))}
  end

  # update the assigns with new map coords for QueryPicker to be able to query the area
  def handle_info({:map_coords, map_coords}, socket) do
    {:noreply, assign(socket, :coords, map_coords)}
  end

  # callback from query-picker form: we build the records for the table
  # we need to transform a record from [id, map_owner, map_pending || map_confirmed, date]
  # to [id, map_owner, map_pending, map_confirmed, date]
  def handle_info({:selected_events, payload}, socket) do
    payload
    |> Enum.map(fn [id, users, date, ad1, ad2, d] = _event ->
      [id, set_all_keys(users), date, ad1, ad2, d]
    end)
    |> then(fn payload ->
      send_update(SelectedEvents, id: "selected", selected: payload)
    end)

    {:noreply, socket}
  end

  def handle_info(%{event: "presence_diff"}, socket) do
    nb_users = Presence.list("presence") |> map_size
    {:noreply, assign(socket, presence: nb_users)}
  end

  defp set_all_keys(users) do
    users
    |> Map.update("owner", [], & &1)
    |> Map.update("pending", [], & &1)
    |> Map.update("confirmed", [], & &1)
  end
end
