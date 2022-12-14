defmodule LiveMapWeb.MapLive do
  use LiveMapWeb, :live_view

  # alias Phoenix.LiveView.JS

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
      ~w(event presence live_chat)s |> Enum.each(&subscribe_to/1)

      {:ok, _} =
        Presence.track(self(), "presence", System.system_time(:second), %{user_id: user_id})
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

  # {
  #   LiveMap.ChatCache.get_messages_by_channel(
  #     assigns.user_id,
  #     assigns.receiver_id
  #   )
  # }

  def retrieve_messages(e, r) do
    LiveMap.ChatCache.get_messages_by_channel(e, r)
    |> Enum.map(fn {t, u, e, r, m} -> [t, u, e, r, m] end)
  end

  @impl true
  def render(assigns) do
    # messages =
    #   if assigns.messages == [],
    #     do: retrieve_messages(assigns.user_id, assigns.receiver_id),
    #     else: assigns.messages

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

  # test JS
  # def handle_event("toggle-show-assign", %{"value" => _v}, socket) do
  #   {:noreply, assign(socket, :show, !socket.assigns.show)}
  # end

  #  backend delete of marker: phx-click from row in "new event table"
  @impl true
  def handle_event("delete_marker", %{"id" => id}, socket) do
    {:noreply, push_event(socket, "delete_marker", %{id: safely_use(id)})}
  end

  #  remove all highlights in Leaflet since checkboxes defaults to false on refresh (no more sync)
  def handle_info({:down_check_all}, socket) do
    {:noreply, push_event(socket, "toggle_all_down", %{})}
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

  def handle_info({:change_receiver_email, receiver_email}, socket) do
    user_id = socket.assigns.user_id
    receiver_id = LiveMap.User.get_by!(:id, email: receiver_email)
    ch = LiveMap.Utils.set_channel(user_id, receiver_id)

    {:noreply,
     assign(socket,
       receiver_id: receiver_id,
       channel: ch,
       message: "",
       user_id: user_id,
       messages: []
     )}
  end

  def handle_info({:set_subscriptions, list}, socket) when length(list) > 1 do
    [t | head] = Enum.reverse(list)

    Enum.each(head, fn u ->
      case LiveMap.ChatCache.check_channel(t, u) do
        nil ->
          LiveMap.ChatCache.new_channel(t, u)
          |> subscribe_to()

        _ ->
          LiveMap.Utils.set_channel(t, u)
          |> subscribe_to()
      end
    end)

    {:noreply, socket}
  end

  def handle_info({:set_subscriptions, _}, socket), do: {:noreply, socket}

  def handle_info({:undo_subscription, []}, socket), do: {:noreply, socket}

  def handle_info({:undo_subscription, [left_id]}, %{assigns: %{p_users: _p_users}} = socket) do
    LiveMap.ChatCache.get_channels(left_id)
    |> Enum.each(fn {ch, _, _} ->
      IO.inspect(ch)
      :ok = Phoenix.PubSub.unsubscribe(LiveMap.PubSub, ch)
      true = LiveMap.ChatCache.rm_channel(ch)
    end)

    {:noreply, socket}
  end

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

  def handle_info(%{event: "presence_diff", payload: %{joins: _joins, leaves: leaves}}, socket) do
    Logger.info("left")
    left = get_ids(leaves)

    send(self(), {:undo_subscription, left})

    list =
      Presence.list("presence")
      |> get_ids()
      |> Enum.uniq()
      |> tap(fn list ->
        send(self(), {:set_subscriptions, list})
      end)
      |> LiveMap.User.get_emails()

    {:noreply, assign(socket, p_users: list)}
  end

  @impl true
  # update all the maps when an event is deleted
  def handle_info(%{topic: "event", event: "delete_event", payload: %{id: id}}, socket) do
    IO.puts("event deleted & pushed")
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
        %{event: "new_message", payload: [current, emitter_id, receiver_id, msg]},
        %{assigns: %{messages: _messages, user_id: user_id}} = socket
      ) do
    socket = assign(socket, :message, "")
    user_id = to_string(user_id)

    cond do
      user_id == emitter_id ->
        {:noreply,
         assign(socket,
           #  messages: [[current, emitter_id, receiver_id, msg] | messages],
           # <--- using temp assigns
           messages: [[current, emitter_id, receiver_id, msg]],
           message: ""
         )}

      user_id == receiver_id ->
        {:noreply,
         assign(socket,
           #  messages: [[current, emitter_id, receiver_id, msg] | messages],
           # <--- using temp assigns
           messages: [[current, emitter_id, receiver_id, msg]],
           message: ""
         )}

      true ->
        {:noreply, socket}
    end
  end

  def subscribe_to(channel) do
    Endpoint.subscribe(channel)
    # Phoenix.PubSub.subscribe(LiveMap.PubSub, channel)
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
end
