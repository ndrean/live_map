defmodule LiveMapWeb.SelectedEvents do
  use LiveMapWeb, :live_component
  import Phoenix.Component
  alias LiveMap.Event

  def mount(_p, s, socket) do
    IO.inspect(s, label: "mout selected")
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    #   socket = assign_events(socket)
    socket = socket |> assign(:checked, false)
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

  def render(assigns) do
    IO.inspect(assigns, label: "assigns")

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
      <tbody>
        <%= for [id, %{"owner" => [owner], "pending"=> pending, "confirmed" => confirmed}, %{"date" => date}] <- @selected do %>
          <tr id={"event-#{id}"}
            class="mb-1"
          >
            <td>
              <%= if (owner == @user) do %>
                <%= link "Delete", to: "#",
                  phx_click: "delete_event",
                  phx_value_id: id,
                  phx_value_owner: owner,
                  data_confirm: "Do you confirm you want to delete this event?",
                  class: "inline-block px-6 py-2.5 bg-yellow-500 text-white font-medium text-xs leading-tight uppercase rounded shadow-md hover:bg-yellow-600 hover:shadow-lg focus:bg-yellow-600 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-yellow-700 active:shadow-lg transition duration-150 ease-in-out"
                %>
              <% else %>
              <%= link "Delete", to: "#",
                phx_click: "delete_event",
                phx_value_id: id,
                phx_value_owner: owner,
                data_confirm: "Do you confirm you want to delete this event?",
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
              <input type="checkbox" phx-click="checkbox" phx-value-id={id}  id={"check-#{id}"}/>
            </td>
            <td>
              <%= if (@user in pending or @user in confirmed) do %>
                <button
                  class="inline-block mr-6 px-2 py-2.5 bg-green-500 text-white font-medium text-xs leading-tight uppercase rounded shadow-md hover:bg-green-600 hover:shadow-lg focus:bg-green-600 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-green-700 active:shadow-lg transition duration-150 ease-in-out"
                  phx-click="send_demand"
                  phx-value-event-id={id}
                  phx-value-user-id={@user_id}

                  > Send demand <%= owner == @user %>
                </button>
              <% else %>
                <button
                    class=" opacity-50 inline-block mr-6 px-2 py-2.5 bg-green-500 text-white font-medium text-xs leading-tight uppercase rounded shadow-md hover:bg-green-600 hover:shadow-lg focus:bg-green-600 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-green-700 active:shadow-lg transition duration-150 ease-in-out"
                    phx-click="send_demand"
                    disabled
                    phx-value-event-id={id}
                    phx-value-user-id={@user_id}

                    > Send demand <%= owner == @user %>
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
        <% end %>
      </tbody>
    </table>
    </div>
    """
  end
end
