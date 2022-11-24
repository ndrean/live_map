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
      Logger.info("#{email} connected")
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

  @impl true
  def render(assigns) do
    # messages =
    #   if assigns.receiver_id != nil do
    #     LiveMap.ChatCache.get_messages_by_channel(assigns.user_id, assigns.receiver_id)
    #   else
    #     []
    #   end

    # IO.inspect(messages, label: "-----------")

    # assigns = assign(assigns, :messages, messages)

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

  def get_ids(list) do
    Enum.map(list, fn {_, data} -> data[:metas] |> List.first() end)
    |> Enum.map(fn %{user_id: id} -> id end)
  end

  def handle_info({:undo_subscription, []}, socket), do: {:noreply, socket}

  def handle_info({:undo_subscription, [left_id]}, %{assigns: %{p_users: _p_users}} = socket) do
    IO.inspect(left_id, label: "left____________")

    LiveMap.ChatCache.get_channels(left_id)
    |> tap(fn res -> IO.inspect(res) end)
    |> Enum.each(fn {ch, _, _} -> Phoenix.PubSub.unsubscribe(LiveMap.PubSub, ch) end)

    {:noreply, socket}
  end

  def handle_info(%{event: "presence_diff", payload: %{joins: _joins, leaves: leaves}}, socket) do
    left =
      get_ids(leaves)
      |> IO.inspect(label: "leaves------------")

    send(self(), {:undo_subscription, left})

    list =
      Presence.list("presence")
      |> get_ids()
      # |> Enum.map(fn {_, data} -> data[:metas] |> List.first() end)
      # |> Enum.map(fn %{user_id: id} -> id end)
      |> Enum.uniq()
      |> tap(fn list ->
        send(self(), {:set_subscriptions, list})
      end)
      |> LiveMap.User.get_emails()

    update = assign(socket, p_users: list)

    {:noreply, update}
  end

  def handle_info({:set_subscriptions, list}, socket) when length(list) > 1 do
    Logger.info("subscriptions")

    [t | head] = Enum.reverse(list)

    Enum.each(head, fn u ->
      case LiveMap.ChatCache.check_channel(t, u) do
        nil ->
          LiveMap.ChatCache.new_channel(t, u)
          |> tap(&IO.inspect(&1, label: "set_new_channel_&_subscribe_____"))
          |> subscribe_to()

        _ ->
          LiveMap.Utils.set_channel(t, u)
          |> tap(&IO.inspect(&1, label: "set_subscription_____"))
          |> subscribe_to()
      end
    end)

    {:noreply, socket}
  end

  def handle_info({:set_subscriptions, _}, socket), do: {:noreply, socket}

  def handle_info(%{event: "toggle_bell", payload: {to, from, receiver_id, _class}}, socket) do
    # ch = set_channel(socket.assigns.user_id, receiver_id)
    # :ok = subscribe_to(ch)

    if receiver_id === socket.assigns.user_id do
      push_event(socket, "notify", %{
        to: to,
        from: from,
        receiver: receiver_id
      })
    end

    # Phoenix.PubSub.unsubscribe(LiveMap.PubSub, socket.assigns.ch)

    #     send_update(HeaderSection, id: "header", newclass: class)
    #     Process.sleep(5_000)

    #     send_update(HeaderSection, id: "header", newclass: "")
    #   end

    # {email, socket.assigns.current, receiver_id, "text-indigo-500 animate-bounce"}
    {:noreply, socket}
  end

  def handle_info({:change_receiver_email, receiver_email}, socket) do
    # Phoenix.PubSub.unsubscribe(LiveMap.PubSub, socket.assigns.channel)
    user_id = socket.assigns.user_id
    receiver_id = LiveMap.User.get_by!(:id, email: receiver_email)

    ch = LiveMap.Utils.set_channel(user_id, receiver_id)
    IO.inspect(ch, label: "change receiver ____________")

    {:noreply,
     assign(socket,
       receiver_id: receiver_id,
       channel: ch,
       message: "",
       user_id: user_id,
       messages: []
     )}
  end

  def handle_info(
        %{topic: ch, event: "new_message", payload: [emitter_id, receiver_id, msg]},
        %{assigns: %{messages: messages, user_id: user_id}} = socket
      ) do
    Logger.info("new message ____________________")
    socket = assign(socket, :message, "")
    IO.inspect(ch, label: "channel new msg ___________")

    IO.inspect(
      "#{socket.assigns.user_id}: ch: #{ch}, user: #{user_id}, emit: #{emitter_id}, receive: #{receiver_id}, #{msg}",
      label: "new msg _______"
    )

    user_id = to_string(user_id)

    cond do
      user_id == emitter_id ->
        IO.inspect("first")

        {:noreply,
         assign(socket,
           messages: [[emitter_id, receiver_id, msg] | messages],
           message: ""
         )}

      user_id == receiver_id ->
        IO.inspect("second")

        {:noreply,
         assign(socket,
           messages: [[emitter_id, receiver_id, msg] | messages],
           message: ""
         )}

      true ->
        IO.inspect("last")
        {:noreply, socket}
    end
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
end
