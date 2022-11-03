defmodule LiveMapWeb.SelectedEvents do
  use LiveMapWeb, :live_component
  import Phoenix.Component
  alias LiveMap.Event
  alias LiveMapWeb.{Endpoint, MailController, SelectedEvents}

  @moduledoc """
  Table to display the results of the query
  """
  def mount(_p, _s, socket) do
    {:ok, assign(socket, live_action: nil)}
  end

  @impl true
  def update(assigns, socket) do
    #   #   socket = assign_events(socket)
    IO.puts("update selected events")

    {:ok, assign(socket, assigns)}
  end

  @doc """
  LiveView will call "handle_call" with updated params whenever we change sorting/filtering
  """
  def handle_params(_p, _url, socket) do
    IO.puts("params ????????")
    {:noreply, assign_events(socket)}
  end

  defp assign_events(socket) do
    assign(socket, :events, Event.list())
  end

  @impl true
  def render(%{selected: nil} = assigns) do
    ~H"""
    <div></div>
    """
  end

  def render(%{selected: []} = assigns) do
    ~H"""
    <div></div>
    """
  end

  def render(assigns) do
    IO.inspect(assigns.flash, label: "flash")

    ~H"""
    <div>
    <table id="selected">
      <thead>
        <tr>
          <th>Action</th>
          <th>Owner</th>
          <th>Date</th>
          <th>Display</th>
          <th>Demande</th>
          <th>Participants</th>
        </tr>
      </thead>
      <tbody :for={[id, %{"owner" => [owner], "pending"=> pending, "confirmed" => confirmed}, %{"date" => date}] <- @selected} >
        <%# for [id, %{"owner" => [owner], "pending"=> pending, "confirmed" => confirmed}, %{"date" => date}] <- @selected do %>
          <tr id={"event-#{id}"}
            class="mb-1"
          >
            <td>
              <%= if (owner == @user) do %>
                <button type="button"
                phx-click= "delete_event",
                  phx-value-id= {id},
                  phx-target= {@myself},
                  phx-value-owner={owner},
                  data-confirm= "Do you confirm you want to delete this event?",
                  class= "inline-block px-6 py-2.5 bg-yellow-500 text-white font-medium text-xs leading-tight uppercase rounded shadow-md hover:bg-yellow-600 hover:shadow-lg focus:bg-yellow-600 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-yellow-700 active:shadow-lg transition duration-150 ease-in-out"
                >Delete
                </button>

              <% else %>
              <%!-- set CSS property "pointer-events: none" to disable button --%>
              <%= link "Delete", to: "#",
                class: "pointer-events-none opacity-50 inline-block px-6 py-2.5 bg-yellow-500 text-white font-medium text-xs leading-tight uppercase rounded shadow-md hover:bg-yellow-600 hover:shadow-lg focus:bg-yellow-600 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-yellow-700 active:shadow-lg transition duration-150 ease-in-out"
              %>

              <% end %>
            </td>
            <td>
              <%= owner %>
            </td>
            <td>
              <%= date %>
            </td>
            <td>
                <%!-- phx-click={JS.dispatch("checkbox:click", to: "#check_#{id}")} --%>
              <input type="checkbox"
                phx-click="checkbox"
                phx-target={@myself}
                phx-value-id={id}
                id={"check_#{id}"}
                />
            </td>
            <td>
            <%# if @live_action in [:show] do %>
            <%!-- <.modal return_to={Routes.live_path(@socket, :index) }> --%>
              <%!-- <Participants.display pending={pending} confirmed={@onfirmed}/> --%>
            <%!-- </.modal> --%>
            <%# end %>

              <%= if (@user in pending or @user in confirmed or owner == @user) do %>
                <button
                  disabled
                  class="opacity-50 inline-block mr-6 px-2 py-2.5 bg-green-500 text-white font-medium text-xs leading-tight uppercase rounded shadow-md hover:bg-green-600 hover:shadow-lg focus:bg-green-600 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-green-700 active:shadow-lg transition duration-150 ease-in-out"
                  > Send demand
                </button>
              <% else %>
                <button
                    class="inline-block mr-6 px-2 py-2.5 bg-green-500 text-white font-medium text-xs leading-tight uppercase rounded shadow-md hover:bg-green-600 hover:shadow-lg focus:bg-green-600 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-green-700 active:shadow-lg transition duration-150 ease-in-out"
                    phx-click="send_demand"
                    phx-target={@myself}
                    phx-value-id={id}
                    phx-value-user-id={@user_id}
                    > Send demand
                  </button>
              <% end %>
            </td>
            <td>
              <%= if pending do %>
                <%= for  user <- pending do %>
                  <span class="text-orange-700"><%= user %></span>,
                <% end %>
              <% end %>
              <%= if confirmed do %>
                <%= for  user <- confirmed do %>
                <span class="text-lime-600"><%= user %></span>,
                <% end %>
              <% end %>
            </td>
          </tr>
        <%# end %>
      </tbody>
    </table>
    </div>
    """
  end

  #   <%= link "Delete", to: "#",
  #   phx_click: "delete_event",
  #   phx_value_id: id,
  #   phx_target: {@myself},
  #   phx_value_owner: owner,
  #   data_confirm: "Do you confirm you want to delete this event?",
  #   class: "inline-block px-6 py-2.5 bg-yellow-500 text-white font-medium text-xs leading-tight uppercase rounded shadow-md hover:bg-yellow-600 hover:shadow-lg focus:bg-yellow-600 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-yellow-700 active:shadow-lg transition duration-150 ease-in-out"
  # %>

  @impl true
  # highlight the event in Leaflet.js when checkbox is ticked in table events
  def handle_event("checkbox", %{"id" => id, "value" => "on"}, socket) do
    id = convert(id)
    {:noreply, push_event(socket, "toggle_up", %{id: id})}
  end

  # remove the highlight in Leaflet when checkbox toggled off in table events
  def handle_event("checkbox", %{"id" => id}, socket) do
    id = convert(id)
    {:noreply, push_event(socket, "toggle_down", %{id: id})}
  end

  # delete event as owner => evt broadcasted to all users
  def handle_event("delete_event", %{"id" => id, "owner" => _owner}, socket) do
    id = convert(id)

    LiveMap.Event.delete_event(id)
    send(self(), {:down_check_all})
    :ok = Endpoint.broadcast!("event", "delete_event", %{id: id})
    selected = rm_event_id_from_selected(socket.assigns.selected, id)
    send_update(SelectedEvents, id: "selected", selected: selected)

    {:noreply, put_flash(socket, :info, "really wanna delete it?")}
  end

  # we send an email from the user to the owner for an event,
  # and update the view to block resending
  # and remove any highlighted event and block the action
  def handle_event("send_demand", %{"id" => id, "user-id" => user_id}, socket) do
    e_id = convert(id)
    user_id = convert(user_id)

    # remove the highlight if the user forgot since the checkbox return to default false on update
    send(self(), {:down_check_all})

    Task.Supervisor.async_nolink(LiveMap.EventSup, fn ->
      %{event_id: e_id, user_id: user_id}
      |> MailController.create_demand()

      # update the table record in SelectEvents
      update_pending_in_selected(socket.assigns.selected, e_id, socket.assigns.user)
      # socket.assigns.selected
      # |> Enum.map(fn [id, users, date] ->
      #   if id == e_id,
      #     do: [
      #       id,
      #       %{users | "pending" => [user_email | users["pending"]]},
      #       date
      #     ],
      #     else: [id, users, date]
      # end)
    end)
    |> then(fn task ->
      selected = Task.await(task)

      # LV callback will update the live_component SelectedEvents
      send_update(SelectedEvents, id: "selected", selected: selected)
    end)

    {:noreply, socket}
  end

  def update_pending_in_selected(selected, e_id, user_email) do
    selected
    |> Enum.map(fn [id, users, date] ->
      if id == e_id,
        do: [
          id,
          %{users | "pending" => [user_email | users["pending"]]},
          date
        ],
        else: [id, users, date]
    end)
  end

  def rm_event_id_from_selected(selected, id) do
    e_id = convert(id)

    selected
    |> Enum.filter(fn [event_id, _, _] -> event_id != e_id end)
  end

  def convert(id), do: if(is_binary(id), do: String.to_integer(id), else: id)
end
