defmodule LiveMapWeb.DatePicker do
  # use Phoenix.LiveComponent
  use LiveMapWeb, :live_component
  alias LiveMap.{DatePicker, Event, GeoJSON}
  alias LiveMapWeb.Endpoint
  require Logger

  def mount(socket) do
    {:ok, assign(socket, :changeset, DatePicker.changeset(%DatePicker{}, %{}))}
  end

  def update(assigns, socket) do
    len = assigns.place["coords"] |> length()

    socket = assign(socket, :len, len)

    {:ok, assign(socket, assigns)}
  end

  def render(%{len: len} = assigns) when len > 1 do
    ~H"""
    <div>
      <.form :let={f} for={@changeset} id="form" phx-submit="up_date" phx-target={@myself}
        class="flex flex-row w-full justify-around space-x-2 px-6"
      >
      <%# display the form when two markers are displayed %>
      <%# if assigns.len>1  do %>
        <%= submit "Update",
        class: "inline-block mr-60 px-6 py-2.5 bg-green-500 text-white font-medium text-xs leading-tight uppercase rounded shadow-md hover:bg-green-600 hover:shadow-lg focus:bg-green-600 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-green-700 active:shadow-lg transition duration-150 ease-in-out"
        %>
        <div >
        <%= date_input(f, :event_date, id: "event_date") %>
        <%= error_tag f, :event_date, class: "text-red-700 text-sm m-1" %>
        </div>
      <%# end %>
      </.form>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div></div>
    """
  end

  def handle_event("up_date", %{"date_picker" => %{"event_date" => date}} = _params, socket) do
    changeset = DatePicker.changeset(%DatePicker{}, %{"event_date" => date})
    IO.inspect(socket.assigns, label: "date")

    case changeset.valid? do
      true ->
        %{user_id: user_id, place: place} = socket.assigns
        create_event(%{"place" => place, "date" => date, "user_id" => user_id}, socket)

      false ->
        {:error, changeset} = Ecto.Changeset.apply_action(changeset, :insert)
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp handle_geojson(%GeoJSON{} = geojson, socket) do
    :ok = Endpoint.broadcast!("event", "new publication", %{geojson: geojson})
    {:noreply, put_flash(socket, :info, "Event saved")}
  end

  defp handle_geojson({:error, _reason}, socket),
    do: {:noreply, put_flash(socket, :error, "Internal error")}

  def create_event(%{"place" => place, "date" => date, "user_id" => user_id}, socket) do
    owner_id = user_id

    Task.Supervisor.async_nolink(LiveMap.EventSup, fn ->
      Event.save_geojson(place, owner_id, date)
    end)
    |> Task.await()
    |> then(fn geojson -> handle_geojson(geojson, socket) end)
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
