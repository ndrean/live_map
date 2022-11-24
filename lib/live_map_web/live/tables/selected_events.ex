defmodule LiveMapWeb.SelectedEvents do
  use LiveMapWeb, :live_component
  use Phoenix.Component
  alias LiveMap.{Event}
  alias LiveMapWeb.{Endpoint, SelectedEvents}
  import LiveMapWeb.LiveHelpers
  import LiveMap.Utils

  @moduledoc """
  Table to display the results of the query
  """

  @thead ~w(Action Display Date Demand Details Owner Participants)s

  def mount(_p, _s, socket) do
    IO.puts("mount SelectedEvents")

    updated =
      socket
      |> assign(
        live_action: nil,
        id: "selected",
        selected: [],
        thead: @thead
      )

    {:ok, updated}
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

  # ########

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
    assigns = assign(assigns, :thead, @thead)

    ~H"""
    <div class="overflow-x-auto overflow-y-auto max-h-60 overflow-hidden">
      <table id="selected" class="table table-compact w-full">
        <thead class="sticky top-0">
          <tr>
            <th :for={th <- @thead}><%= th %></th>
          </tr>
        </thead>
        <tbody>
          <tr
            :for={
              [
                id,
                %{"owner" => [owner], "pending" => pending, "confirmed" => confirmed},
                %{"date" => date},
                %{"ad1" => _ad1},
                %{"ad2" => _ad2},
                %{"d" => d}
              ] <-
                @selected
            }
            id={"event-#{id}"}
            class="mb-1"
          >
            <td>
              <%!-- Notice class "pointer-events-none" --%>
              <button
                type="button"
                phx-click="delete_event"
                phx-value-id={id}
                phx-target={@myself}
                phx-value-owner={owner}
                data-confirm="Do you confirm you want to delete this event?"
                disabled={owner != @current}
                class="inline-block m-1 px-2  py-2.5 bg-yellow-500 text-red-700 font-medium text-xs leading-tight uppercase rounded shadow-md hover:bg-yellow-600 hover:shadow-lg focus:bg-yellow-600 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-yellow-700 active:shadow-lg transition duration-150 ease-in-out"
              >
                <%!-- ml-1 mr-1 --%>
                <.bin_svg :if={owner == @current} />
              </button>
            </td>
            <td>
              <input
                type="checkbox"
                phx-click="checkbox"
                phx-target={@myself}
                phx-value-id={id}
                id={"check_#{id}"}
                class="checkbox checkbox-lg m-2"
              />
            </td>
            <td>
              <div class={[
                "font-['Roboto'] font-bold text-sm m-1",
                @current in confirmed && "text-lime-500",
                @current in pending && "text-blue-700",
                @current == owner && "text-white"
              ]}>
                <%= date %>
              </div>
            </td>
            <td>
              <button
                phx-click="send_demand"
                phx-target={@myself}
                phx-value-id={id}
                phx-value-user_id={@user_id}
                disabled={@current in pending or @current in confirmed or owner == @current}
                class={[
                  "inline-block m-1 px-2 py-2.5 bg-green-500 text-white font-medium text-xs leading-tight uppercase rounded shadow-md hover:bg-green-600 hover:shadow-lg focus:bg-green-600 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-green-700 active:shadow-lg transition duration-150 ease-in-out"
                ]}
              >
                <.send_svg :if={
                  !(@current in pending or @current in confirmed or owner == @current) &&
                    only_futur?(date)
                } />
              </button>
            </td>
            <td>
              <pre><%= d %></pre>
            </td>
            <td>
              <%= owner %>
            </td>
            <td>
              <span :for={user <- pending} class={[pending != [] && "text-orange-700"]}>
                <%= user %>
              </span>
              <span :for={user <- confirmed} class={[confirmed != [] && "text-lime-600"]}>
                <%= user %>
              </span>
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
    {:noreply, push_event(socket, "toggle_up", %{id: safely_use(id)})}
  end

  # remove the highlight in Leaflet when checkbox toggled off in table events
  def handle_event("checkbox", %{"id" => id}, socket) do
    {:noreply, push_event(socket, "toggle_down", %{id: safely_use(id)})}
  end

  # delete event as owner => evt broadcasted to all users
  def handle_event("delete_event", %{"id" => id, "owner" => _owner}, socket) do
    id = safely_use(id)
    # send async mail & then delete event
    send(self(), {:mail_to_cancel_event, %{event_id: id}})
    # remove the check on all checkboxes
    send(self(), {:down_check_all})
    # broadcast to the front-end to remove the event
    Endpoint.broadcast!("event", "delete_event", %{id: id})
    # update the user's table
    selected = rm_event_id_from_selected(socket.assigns.selected, id)
    send_update(SelectedEvents, id: "selected", selected: selected)
    {:noreply, put_flash(socket, :info, "Confirm deletion?")}
  end

  # we send an email from the user to the owner for an event,
  # and update the view to block resending
  # and remove any highlighted event and block the action
  def handle_event("send_demand", %{"id" => id, "user_id" => user_id}, socket) do
    e_id = safely_use(id)
    user_id = safely_use(user_id)
    # remove the highlight if the user forgot since the checkbox return to default false on update
    send(self(), {:down_check_all})
    # make async call to mailer
    send(self(), {:create_demand, %{event_id: e_id, user_id: user_id}})
    # update the table record in SelectEvents
    selected = update_pending_in_selected(socket.assigns.selected, e_id, socket.assigns.current)
    # LV callback will update the live_component SelectedEvents
    {:phoenix, :send_update, _} = send_update(SelectedEvents, id: "selected", selected: selected)

    {:noreply, socket}
  end

  def update_pending_in_selected(selected, e_id, user_email) do
    Enum.map(selected, fn [id, users, date, ad1, ad2, d] ->
      if id == e_id,
        do: [
          id,
          %{users | "pending" => [user_email | users["pending"]]},
          date,
          ad1,
          ad2,
          d
        ],
        else: [id, users, date, ad1, ad2, d]
    end)
  end

  def rm_event_id_from_selected(selected, id) do
    e_id = safely_use(id)
    Enum.filter(selected, fn [event_id, _, _, _, _, _] -> event_id != e_id end)
  end

  def only_futur?(date_string) do
    Date.compare(parse_date(date_string), Date.utc_today() |> Date.add(-1)) == :gt
  end
end
