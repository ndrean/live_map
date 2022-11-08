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
    ~H"""
    <div class="overflow-x-auto">
    <table id="selected" class="table table-compact w-full">
      <thead>
        <tr>
          <th class="text-white font-['Roboto']">Action</th>
          <th class="text-white font-['Roboto']">Display</th>
          <th class="text-white font-['Roboto']">
            <div class="tooltip tooltip-above data" data-tip="blue-pending, green-confirmed">
              Date
            </div>
            </th>
          <th class="text-white font-['Roboto']">Demande</th>
          <th class="text-white font-['Roboto']">Owner</th>
          <th class="text-white font-['Roboto']">Participants</th>
        </tr>
      </thead>
      <p @selected></p>

      <tbody :for={[id, %{"owner" => [owner], "pending"=> pending, "confirmed" => confirmed}, %{"date" => date}] <- @selected}
        class="overflow-x-auto"
      >
        <tr id={"event-#{id}"} class="mb-1">
          <td>
            <%= if (owner == @user) do %>
              <button type="button"
                phx-click= "delete_event",
                phx-value-id= {id},
                phx-target= {@myself},
                phx-value-owner={owner},
                data-confirm= "Do you confirm you want to delete this event?",
                class= "inline-block ml-1 mr-1 px-6 py-2.5 bg-yellow-500 text-red-700 font-medium text-xs leading-tight uppercase rounded shadow-md hover:bg-yellow-600 hover:shadow-lg focus:bg-yellow-600 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-yellow-700 active:shadow-lg transition duration-150 ease-in-out"
              >
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
                <path stroke-linecap="round" stroke-linejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" />
              </svg>
              </button>

            <% else %>
              <%!-- set CSS property "pointer-events: none" to disable button --%>
              <button
              class="pointer-events-none ml-1 mr-1 opacity-50 inline-block px-6 py-2.5 bg-yellow-500 text-white font-medium text-xs leading-tight uppercase rounded shadow-md hover:bg-yellow-600 hover:shadow-lg focus:bg-yellow-600 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-yellow-700 active:shadow-lg transition duration-150 ease-in-out"
              >
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" />
                </svg>
              </button>
              <%# link "Delete", to: "#",
                class: "pointer-events-none opacity-50 inline-block px-6 py-2.5 bg-yellow-500 text-white font-medium text-xs leading-tight uppercase rounded shadow-md hover:bg-yellow-600 hover:shadow-lg focus:bg-yellow-600 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-yellow-700 active:shadow-lg transition duration-150 ease-in-out"
              %>
            <% end %>
          </td>
          <td >
            <input type="checkbox" phx-click="checkbox" phx-target={@myself}
              phx-value-id={id} id={"check_#{id}"} class="checkbox checkbox-lg m-2"
            />
          </td>
          <td>
            <%= if (@user in confirmed) do %>
              <div class="text-lime-500 font-['Roboto'] font-bold text-sm m-1"> <%= date %></div>
            <% else %>
              <%= if (@user in pending) do %>
                <div class="text-blue-800  00 font-['Roboto'] font-bold text-sm m-1"> <%= date %></div>
              <% else %>
                <div class="text-white font-['Roboto'] text-sm m-1"> <%= date %></div>
              <% end %>
            <% end %>
          </td>
          <td>
            <%= if (@user in pending or @user in confirmed or owner == @user) do %>
              <button disabled
                class="opacity-50 inline-block m-1 px-2 py-2.5 bg-green-500 text-white font-medium text-xs leading-tight uppercase rounded shadow-md hover:bg-green-600 hover:shadow-lg focus:bg-green-600 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-green-700 active:shadow-lg transition duration-150 ease-in-out"
                >
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M6 12L3.269 3.126A59.768 59.768 0 0121.485 12 59.77 59.77 0 013.27 20.876L5.999 12zm0 0h7.5" />
                </svg>
              </button>
            <% else %>
              <button
                  class="inline-block m-1 px-2 py-2.5 bg-green-500 text-white font-medium text-xs leading-tight uppercase rounded shadow-md hover:bg-green-600 hover:shadow-lg focus:bg-green-600 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-green-700 active:shadow-lg transition duration-150 ease-in-out"
                  phx-click="send_demand"
                  phx-target={@myself}
                  phx-value-id={id}
                  phx-value-user-id={@user_id}
                  >
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 12L3.269 3.126A59.768 59.768 0 0121.485 12 59.77 59.77 0 013.27 20.876L5.999 12zm0 0h7.5" />
                  </svg>
                </button>
            <% end %>
          </td>
          <td>
            <%= owner %>
          </td>
            <%# if @live_action in [:show] do %>
            <%!-- <.modal return_to={Routes.live_path(@socket, :index) }> --%>
              <%!-- <Participants.display pending={pending} confirmed={@onfirmed}/> --%>
            <%!-- </.modal> --%>
            <%# end %>


          <td>
            <%= if (pending != []) do %>
                <span :for={user <- pending} class="text-orange-700">
                  <%= user %>
                </span>,
            <% end %>
            <%= if (confirmed != []) do %>
              <span :for={user <- confirmed} class="text-lime-600"><%= user %></span>,
            <% end %>
          </td>
        </tr>
      </tbody>
    </table>

    </div>
    """
  end

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

    {:noreply, put_flash(socket, :info, "Confirm u wanna delete?")}
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
