defmodule LiveMapWeb.NewEvent do
  use LiveMapWeb, :live_component
  import Phoenix.Component
  alias LiveMap.{Event, NewEvent}
  alias LiveMapWeb.Endpoint
  require Logger

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(
        len: assigns.place["coords"] |> length(),
        # new_event: %NewEvent{},
        changeset: NewEvent.changeset(%NewEvent{})
      )

    {:ok, assign(socket, assigns)}
  end

  #  display the form when two markers are displayed
  def render(%{len: len} = assigns) when len > 1 do
    ~H"""
    <div id="date_form">
      <.form :let={f}
        for={@changeset}
        id="form"
        phx-change="validate"
        phx-submit="up_date"
        phx-target={@myself}

        class="flex flex-row w-full justify-around space-x-2 px-2"
      >
        <button type="submit"
          class="inline-block  px-2 py-2 mr-4 bg-green-500 text-white font-medium text-xs leading-tight uppercase rounded shadow-md hover:bg-green-600 hover:shadow-lg focus:bg-green-600 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-green-700 active:shadow-lg transition duration-150 ease-in-out"
        > Update
        </button>
        <%= date_input(f, :event_date, id: "event_date", class: "w-30 px-2") %>
        <%= error_tag f, :event_date, class: "text-red-700 text-sm m-1" %>
      </.form>
    </div>
    """
  end

  # no form to render if no event to display
  def render(assigns) do
    ~H"""
    <div></div>
    """
  end

  # adds real-time validation
  def handle_event("validate", %{"new_event" => %{"event_date" => date}}, socket) do
    changeset =
      %NewEvent{}
      |> NewEvent.changeset(%{"event_date" => date})
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  # save new event and broadcast to every user
  def handle_event("up_date", %{"new_event" => %{"event_date" => date}}, socket) do
    %{user_id: owner_id, place: place} = socket.assigns

    case Event.save_geojson(place, owner_id, date) do
      {:error, changeset} ->
        case event_date_blank?(changeset) do
          true ->
            changeset =
              %NewEvent{}
              |> NewEvent.changeset(%{"event_date" => date})
              |> Map.put(:action, :insert)

            {:noreply, assign(socket, :changeset, changeset)}

          false ->
            socket = assign(socket, :changeset, changeset)
            send(self(), "flash_update")
            {:noreply, push_event(socket, "clear_event", %{})}
        end

      {:ok, geojson} ->
        # broadcast to all users a new event
        :ok = Endpoint.broadcast!("event", "new_event", %{geojson: geojson})
        {:noreply, socket}
    end
  end

  def event_date_blank?(%Ecto.Changeset{errors: [date: {"can't be blank", _}]}), do: true
  def event_date_blank?(_), do: false
end
