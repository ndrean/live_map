defmodule LiveMapWeb.NewEvent do
  use LiveMapWeb, :live_component
  import Phoenix.Component
  alias LiveMap.{Event, NewEvent}
  alias LiveMapWeb.Endpoint
  import LiveMapWeb.LiveHelpers
  require Logger

  def mount(socket) do
    {:ok,
     socket
     |> assign(:date, "")
     |> assign(:changeset, NewEvent.changeset(%NewEvent{}))}
  end

  def update(assigns, socket) do
    IO.puts("update new event")
    socket = assign(socket, len: assigns.place["coords"] |> length())

    {:ok, assign(socket, assigns)}
  end

  attr(:date, :string)
  attr(:errors, :list)
  attr(:class, :string)
  attr(:class_err, :string)

  #  display the form when two markers are displayed
  def render(%{len: len} = assigns) when len > 1 do
    # assigns =
    #   assigns
    #   |> assign_new(:date, fn ->  assigns.date)

    ~H"""
    <div id="date_form">
      <.form
        for={@changeset}
        id="new_event"
        phx-change="validate"
        phx-submit="up_date"
        phx-target={@myself}

        class="flex flex-row w-full justify-around content-evenly space-x-2 px-2"
      >
        <button form="new_event"
          class="inline-block  px-2 py-2 mr-4 bg-green-500 text-white font-medium text-xs leading-tight uppercase rounded shadow-md hover:bg-green-600 hover:shadow-lg focus:bg-green-600 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-green-700 active:shadow-lg transition duration-150 ease-in-out"
        > Update
        </button>
        <.date_err name="new_event[date]" class="w-30 px-2" date={@date} label="Date"
          class_err="mt-1"  errors={@changeset.errors}
        />
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
  def handle_event("validate", %{"new_event" => %{"date" => date} = params}, socket) do
    changeset =
      %NewEvent{}
      |> NewEvent.changeset(params)
      |> Map.put(:action, :validate)

    socket =
      socket
      |> assign(:changeset, changeset)
      |> assign(:date, date)

    {:noreply, socket}
  end

  def handle_event("up_date", params, %{assigns: %{changeset: %{valid?: false}}} = socket) do
    changeset =
      NewEvent.changeset(%NewEvent{}, params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  # save new event and broadcast to every user
  def handle_event("up_date", %{"new_event" => params}, socket) do
    %{user_id: owner_id, place: place} = socket.assigns

    {status, response} =
      Event.into_params(place, owner_id, params["date"])
      |> Event.save()

    case {status, response} do
      {:error, changeset} ->
        send(self(), {:push_flash, :error_event_creation, inspect(changeset.errors)})
        {:noreply, socket}

      {:ok, %LiveMap.GeoJSON{} = geojson} ->
        # broadcast to all users a new event
        :ok = Endpoint.broadcast!("event", "new_event", %{geojson: geojson})
        {:noreply, socket}
    end
  end
end
