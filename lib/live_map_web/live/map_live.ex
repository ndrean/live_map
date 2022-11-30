defmodule LiveMapWeb.MapLive do
  use LiveMapWeb, :live_view

  # alias Phoenix.LiveView.JS

  alias LiveMap.{Cache, Utils, User, Event}

  alias LiveMapWeb.{
    SelectedEvents,
    Chart,
    QueryPicker,
    HeaderSection,
    MailController,
    ChatLive,
    Presence,
    Endpoint
  }

  require Logger
  import LiveMap.Utils, only: [safely_use: 1]

  @impl true
  def mount(_params, %{"email" => email, "user_id" => user_id} = _session, socket) do
    if connected?(socket) && email == LiveMap.User.get_by!(:email, id: user_id) do
      Logger.info("#{email} connected--------------------")

      ~w(event presence)s |> Enum.each(&subscribe_to/1)

      {:ok, _} = Presence.track(self(), "presence", System.os_time(:second), %{user_id: user_id})
    end

    {:ok,
     assign(socket,
       current: email,
       user_id: user_id,
       receiver_id: nil,
       selected: nil,
       coords: %{},
       messages: [],
       message: "",
       show: false,
       temporary_assigns: [messages: []],
       p_users: [],
       channel: ""
     )}
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :messages, retrieve_messages(assigns.user_id, assigns.receiver_id))

    ~H"""
    <div id="live">
      <.live_component
        module={HeaderSection}
        id="header"
        user_id={@user_id}
        current={@current}
        p_users={@p_users}
        channel={@channel}
      />

      <.live_component module={Chart} id="map" current={@current} user_id={@user_id} coords={@coords} />

      <.live_component
        module={ChatLive}
        id="chat"
        current={@current}
        user_id={@user_id}
        messages={@messages}
        message={@message}
        receiver_id={@receiver_id}
        channel={@channel}
      />

      <.live_component
        module={QueryPicker}
        id="query_picker"
        current={@current}
        user_id={@user_id}
        coords={@coords}
      />

      <.live_component
        module={SelectedEvents}
        id="selected"
        selected={@selected}
        user_id={@user_id}
        current={@current}
      />
    </div>
    """
  end

  #  backend delete of marker: phx-click from row in "new event table"
  @impl true
  def handle_event("delete_marker", %{"id" => id}, socket) do
    {:noreply, push_event(socket, "delete_marker", %{id: safely_use(id)})}
  end

  #  remove all highlights in Leaflet since checkboxes defaults to false on refresh (no more sync)
  @impl true
  def handle_info({:down_check_all}, socket) do
    {:noreply, push_event(socket, "toggle_all_down", %{})}
  end

  @impl true
  def handle_info({:mail_to_cancel_event, %{event_id: id}}, socket) do
    MailController.cancel_event(%{event_id: id})
    Event.delete_event(id)
    {:noreply, put_flash(socket, :info, "Cancelation mail is sent")}
  end

  @impl true
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
  @impl true
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

  @impl true
  def handle_info({:change_receiver_email, receiver_email}, socket) do
    user_id = socket.assigns.user_id
    receiver_id = User.get_by!(:id, email: receiver_email)
    channel = Utils.set_channel(user_id, receiver_id)

    {:noreply,
     assign(socket,
       receiver_id: receiver_id,
       channel: channel,
       message: "",
       user_id: user_id,
       messages: []
     )}
  end

  @impl true
  def handle_info({:set_subscriptions, list}, socket) when length(list) > 1 do
    [t | head] = Enum.reverse(list)
    user_id = socket.assigns.user_id

    case t == user_id do
      true ->
        Enum.each(head, fn u ->
          Utils.set_channel(t, u)
          |> subscribe_to()
        end)

      false ->
        [u] = Enum.filter(head, fn u -> u == user_id end)

        if u != nil,
          do:
            Utils.set_channel(t, u)
            |> subscribe_to()

        # Enum.each(head, fn u ->
        #   if u == user_id,
        #     do:
        #       Utils.set_channel(t, u)
        #       |> subscribe_to()
        # end)
    end

    {:noreply, socket}
  end

  def handle_info({:set_subscriptions, _}, socket), do: {:noreply, socket}

  def handle_info({:undo_subscription, []}, socket), do: {:noreply, socket}

  @impl true
  def handle_info({:undo_subscription, [left_id]}, %{assigns: %{user_id: user_id}} = socket) do
    Utils.set_channel(left_id, user_id)
    |> unsubscribe_to()

    {:noreply, socket}
  end

  @impl true
  def handle_info(
        %{event: "toggle_bell", payload: {from, to, receiver_id, class}},
        socket
      ) do
    if receiver_id === socket.assigns.user_id do
      send_update(HeaderSection, id: "header", newclass: class)
    end

    {:noreply,
     push_event(socket, "notify", %{
       to: to,
       from: from,
       receiver: receiver_id
     })}
  end

  @impl true
  def handle_info(
        %{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
        socket
      ) do
    cond do
      joins == %{} ->
        list = get_ids(leaves)
        send(self(), {:undo_subscription, list})

        list =
          Presence.list("presence")
          |> get_ids()
          |> Enum.uniq()
          |> User.get_emails()

        {:noreply, assign(socket, p_users: list)}

      leaves == %{} ->
        list =
          Presence.list("presence")
          |> get_ids()
          |> Enum.uniq()
          |> tap(fn list ->
            send(self(), {:set_subscriptions, list})
          end)
          |> User.get_emails()

        {:noreply, assign(socket, p_users: list)}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  # update all the maps when an event is deleted
  def handle_info(%{topic: "event", event: "delete_event", payload: %{id: id}}, socket) do
    {:noreply, push_event(socket, "delete_event", %{id: id})}
  end

  # broadcast new event to all users from the date_picker form
  @impl true
  def handle_info(
        %{topic: "event", event: "new_event", payload: %{geojson: geojson}},
        socket
      ) do
    {:noreply, push_event(socket, "new_pub", %{geojson: geojson})}
  end

  def handle_info(
        %{topic: _topic, event: "new_message", payload: {current, emitter_id, receiver_id, msg}},
        %{assigns: %{messages: _messages, user_id: user_id}} = socket
      ) do
    socket = assign(socket, :message, "")
    user_id = to_string(user_id)

    case check_user_concerned(user_id, emitter_id, receiver_id) do
      true ->
        {:noreply,
         assign(socket,
           #  messages: [[current, emitter_id, receiver_id, msg] | messages],
           # <--- using temp assigns
           messages: [[current, emitter_id, receiver_id, msg]],
           message: ""
         )}

      false ->
        {:noreply, socket}
    end
  end

  def check_user_concerned(u, e, r) do
    ((u == e or u == r) && true) || false
  end

  def subscribe_to(channel) do
    Endpoint.subscribe(channel)
  end

  def unsubscribe_to(channel) do
    Endpoint.unsubscribe(channel)
  end

  def broadcast!(channel, event, msg) do
    Phoenix.PubSub.broadcast!(channel, event, msg)
  end

  def get_ids(list) do
    Enum.map(list, fn {_, data} -> data[:metas] |> List.first() end)
    |> Enum.map(fn %{user_id: id} -> id end)
  end

  defp set_all_keys(users) do
    users
    |> Map.update("owner", [], & &1)
    |> Map.update("pending", [], & &1)
    |> Map.update("confirmed", [], & &1)
  end

  def retrieve_messages(e, r) do
    Cache.get_messages_by_channel(e, r)
    |> Enum.map(fn {t, u, e, r, m} -> [t, u, e, r, m] end)
  end

  def list_subscriptions() do
    Registry.keys(LiveMap.PubSub, self())
    |> Enum.filter(fn ch -> ch != "event" and ch != "presence" end)
  end
end
