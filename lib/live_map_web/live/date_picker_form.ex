defmodule LiveMapWeb.DatePicker do
  # use Phoenix.LiveComponent
  use LiveMapWeb, :live_component
  alias LiveMap.DatePicker
  require Logger

  def mount(socket) do
    {:ok, assign(socket, :changeset, DatePicker.changeset(%DatePicker{}, %{}))}
  end

  def update(assigns, socket) do
    len = assigns.place["coords"] |> length()

    socket =
      socket
      |> assign(:len, len)

    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.form :let={f} for={@changeset} id="form" phx-submit="up_date" phx-target={@myself}
        class="flex flex-row w-full"
      >
        <div >
          <%= date_input(f, :event_date, id: "event_date") %>
          <%= error_tag f, :event_date, class: "text-red-700 text-sm m-1" %>
        </div>
        <%# display the form when two markers are displayed %>
        <%= if assigns.len>1  do %>
          <%= submit "send",
          class: "inline-block px-6 py-2.5 bg-green-500 text-white font-medium text-xs leading-tight uppercase rounded shadow-md hover:bg-green-600 hover:shadow-lg focus:bg-green-600 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-green-700 active:shadow-lg transition duration-150 ease-in-out"
          %>
        <% end %>
      </.form>
    </div>
    """
  end

  def handle_event("up_date", %{"date_picker" => %{"event_date" => date}} = _params, socket) do
    changeset = DatePicker.changeset(%DatePicker{}, %{"event_date" => date})

    case changeset.valid? do
      true ->
        # send_update(MapComp, id: "map", event: socket.assigns)
        send(self(), {:newintown, %{"place" => socket.assigns.place, "date" => date}})
        {:noreply, socket}

      false ->
        {:error, changeset} = Ecto.Changeset.apply_action(changeset, :insert)
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end

# <form  phx-submit="update" phx-target={@myself}>
#   <div class="flex items-center justify-center">
#     <div class="datepicker relative form-floating mb-3 xl:w-96" data-mdb-toggle-button="datepicker">
#       <input type="date" name="event_date"
#         class="form-control block w-full px-3 py-1.5 text-base font-normal text-gray-700 bg-white bg-clip-padding border border-solid border-gray-300 rounded transition ease-in-out m-0 focus:text-gray-700 focus:bg-white focus:border-blue-600 focus:outline-none"
#       >
#     </div>
#   </div>
#   <input type="submit" name="save_event" disabled={@length<2}
#     class="inline-block px-6 py-2.5 bg-green-500 text-white font-medium text-xs leading-tight uppercase rounded shadow-md hover:bg-green-600 hover:shadow-lg focus:bg-green-600 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-green-700 active:shadow-lg transition duration-150 ease-in-out"
#   >
# </form>
