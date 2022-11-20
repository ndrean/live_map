defmodule LiveMapWeb.MapLive do
  use LiveMapWeb, :live_view

  # alias Phoenix.LiveView.JS

  alias LiveMapWeb.{
    SelectedEvents,
    MapComp,
    QueryPicker,
    HeaderSection,
    MailController,
    ChatLive,
    Presence,
    Endpoint
  }

  require Logger
  import LiveMap.Utils, only: [safely_use: 1]

  @presence_channel "presence"

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket) do
      ~w(event presence live_chat)s |> Enum.each(&subscribe_to/1)
      {:ok, _} = Presence.track(self(), "presence", socket.id, %{user_id: session["user_id"]})
    end

    {:ok,
     assign(socket,
       current: session["email"],
       user_id: session["user_id"],
       user_token: session["user_token"],
       receiver_id: nil,
       selected: nil,
       coords: %{},
       messages: [],
       message: "",
       show: false,
       temporary_assigns: [messages: []],
       p_users: []
     )}
  end

  # emails={@p_users}

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.live_component module={HeaderSection} id="header"
        current={@current}
        list_ids={@p_users}
        length={length(@p_users)  == 1}
      />

      <.live_component module={MapComp} id="map"
        current={@current}
        user_id={@user_id}
        coords={@coords}
      />

      <%!-- <button class="text-black" phx-click="toggle-show-assign">show or hide</button>
      <div
            :if={@show}
            class="hidden text-black"
            phx-remove={
              JS.hide(transition: {"ease-out duration-1000", "opacity-100", "opacity-0"}, time: 1000)
            }
            phx-mounted={
              JS.show(transition: {"ease-in duration-1000", "opacity-0", "opacity-100"}, time: 1000)
            }
          >
            I fade in or out when you click the button
      </div> --%>

      <.live_component module={ChatLive} id="chat"
        current={@current}
        user_id={@user_id}
        messages={@messages}
        message={@message}
        receiver_id={@receiver_id}
      />

      <.live_component module={QueryPicker} id="query_picker"
        current={@current}
        user_id={@user_id}
        coords={@coords}
      />

      <.live_component module={SelectedEvents} id="selected"
        selected={@selected}
        user_id={@user_id}
        current={@current}
      />
    </div>
    """
  end

  # test JS
  # def handle_event("toggle-show-assign", %{"value" => _v}, socket) do
  #   {:noreply, assign(socket, :show, !socket.assigns.show)}
  # end

  #  backend delete of marker: phx-click from row in "new event table"
  @impl true
  def handle_event("delete_marker", %{"id" => id}, socket) do
    {:noreply, push_event(socket, "delete_marker", %{id: safely_use(id)})}
  end

  @impl true
  # update all the maps when an event is deleted
  def handle_info(%{topic: "event", event: "delete_event", payload: %{id: id}}, socket) do
    IO.puts("event deleted & pushed")
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

  def handle_info({:mail_to_cancel_event, %{event_id: id}}, socket) do
    MailController.cancel_event(%{event_id: id})
    LiveMap.Event.delete_event(id)
    {:noreply, put_flash(socket, :info, "Cancelation mail is sent")}
  end

  def handle_info({:create_demand, %{event_id: e_id, user_id: user_id}}, socket) do
    MailController.create_demand(%{event_id: e_id, user_id: user_id})
    {:noreply, put_flash(socket, :info, "Participation demand sent by mail")}
  end

  # example of error: bad user_id
  def handle_info("flash_error", socket) do
    {:noreply, put_flash(socket, :error, "Event not saved due to error")}
  end

  def handle_info("flash_update", socket) do
    {:noreply, put_flash(socket, :error, "Update error")}
  end

  # generic handler to display flash from child
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
    socket =
      assign(socket, %{
        presence: Presence.list(@presence_channel) |> map_size,
        p_users:
          Presence.list(@presence_channel)
          |> Enum.map(fn {_, data} ->
            data[:metas]
            |> List.first()
          end)
      })

    {:noreply, socket}
  end

  def handle_info({:receiver_id, receiver_id}, socket) do
    send_update(ChatLive, id: "chat", receiver_id: receiver_id)
    {:noreply, assign(socket, :receiver_id, receiver_id)}
  end

  def handle_info(
        %{topic: "live_chat", event: "new_message", payload: [emitter_id, receiver_id, msg]},
        %{assigns: %{messages: messages}} = socket
      ) do
    socket = assign(socket, :message, "")

    {:noreply,
     assign(socket,
       messages: [[emitter_id, receiver_id, msg] | messages] |> :lists.reverse(),
       message: ""
     )}
  end

  def subscribe_to(channel) do
    Endpoint.subscribe(channel)
  end

  defp set_all_keys(users) do
    users
    |> Map.update("owner", [], & &1)
    |> Map.update("pending", [], & &1)
    |> Map.update("confirmed", [], & &1)
  end

  # def assign_chat(emitter, receiver) do
  # LiveMap.ChatCache.get_messages_by_user(user_email)
  # |> Enum.map(fn {_t, user_email, msg} -> [user_email, msg] end)
  # end
end
