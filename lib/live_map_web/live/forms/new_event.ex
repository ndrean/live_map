defmodule LiveMapWeb.NewEvent do
  use LiveMapWeb, :live_component
  alias LiveMap.{Event, GeoJSON}
  alias LiveMapWeb.{Endpoint}
  alias LiveMap.NewEvent
  require Logger

  def mount(socket) do
    {:ok,
     assign(socket,
       new_event: %NewEvent{},
       changeset: NewEvent.changeset(%NewEvent{})
     )}
  end

  def update(assigns, socket) do
    len = assigns.place["coords"] |> length()
    socket = assign(socket, :len, len)
    {:ok, assign(socket, assigns)}
  end

  # phx-change="validate"

  #  display the form when two markers are displayed
  def render(%{len: len} = assigns) when len > 1 do
    ~H"""
    <div id="date_form">
      <.form :let={f}
        for={@changeset}
        id="form"
        phx-submit="up_date"
        phx-target={@myself}
        class="flex flex-row w-full justify-around space-x-2 px-6"
      >
        <%= submit "Update",
        class: "inline-block mr-60 px-6 py-2.5 bg-green-500 text-white font-medium text-xs leading-tight uppercase rounded shadow-md hover:bg-green-600 hover:shadow-lg focus:bg-green-600 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-green-700 active:shadow-lg transition duration-150 ease-in-out"
        %>
        <div >
        <%= date_input(f, :event_date, id: "event_date") %>
        <%= error_tag f, :event_date, class: "text-red-700 text-sm m-1" %>
        </div>
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

  # def handle_event("validate", %{"new_event"}) do
  # save new event and broadcast to every user
  def handle_event("up_date", %{"new_event" => %{"event_date" => date}} = _params, socket) do
    changeset = NewEvent.changeset(%NewEvent{}, %{"event_date" => date})

    case changeset.valid? do
      true ->
        %{user_id: user_id, place: place} = socket.assigns
        create_event(%{"place" => place, "date" => date, "user_id" => user_id}, socket)

      false ->
        {:error, changeset} = Ecto.Changeset.apply_action(changeset, :insert)
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def create_event(%{"place" => place, "date" => date, "user_id" => user_id}, socket) do
    owner_id = user_id

    Task.Supervisor.async_nolink(LiveMap.EventSup, fn ->
      Event.save_geojson(place, owner_id, date)
    end)
    |> Task.await()
    |> then(fn geojson -> handle_geojson(geojson, socket) end)
  end

  defp handle_geojson(%GeoJSON{} = geojson, socket) do
    :ok = Endpoint.broadcast!("event", "new event", %{geojson: geojson})
    {:noreply, put_flash(socket, :info, "Event saved")}
  end

  defp handle_geojson({:error, _reason}, socket),
    do: {:noreply, put_flash(socket, :error, "Internal error")}
end
