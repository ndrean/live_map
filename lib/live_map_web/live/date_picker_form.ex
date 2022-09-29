defmodule LiveMapWeb.DatePicker do
  # use Phoenix.LiveComponent
  use LiveMapWeb, :live_component
  alias LiveMap.DatePicker

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    IO.inspect(self(), label: "date")
    # socket =
    #   socket
    #   |> assign(:changeset, DatePicker.changeset(%{}))

    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    ~H"""
      <form  phx-submit="update" phx-target={@myself}>
        <div class="flex items-center justify-center">
          <div class="datepicker relative form-floating mb-3 xl:w-96" data-mdb-toggle-button="datepicker">
            <input type="date" name="event_date"
              class="form-control block w-full px-3 py-1.5 text-base font-normal text-gray-700 bg-white bg-clip-padding border border-solid border-gray-300 rounded transition ease-in-out m-0 focus:text-gray-700 focus:bg-white focus:border-blue-600 focus:outline-none"
            >
          </div>
        </div>
        <input type="submit" name="save_event" disabled={length(@place["coords"])<2}
          class="inline-block px-6 py-2.5 bg-green-500 text-white font-medium text-xs leading-tight uppercase rounded shadow-md hover:bg-green-600 hover:shadow-lg focus:bg-green-600 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-green-700 active:shadow-lg transition duration-150 ease-in-out"
        >
      </form>

    """
  end

  def handle_event("update", %{"event_date" => _date} = params, socket) do
    changeset = DatePicker.changeset(params)

    case changeset do
      %{valid?: true} ->
        %{changes: %{event_date: date}} = changeset

        socket =
          socket
          |> assign(:date, date)

        # send_update(MapComp, id: "map", event: socket.assigns)
        send(self(), {:newintown, %{"place" => socket.assigns.place, "date" => date}})

        {:noreply, socket}

      %{errors: msg} ->
        socket = put_flash(socket, :error, "#{inspect(msg)}")
        {:noreply, socket}
    end
  end
end
