defmodule LiveMapWeb.Chart do
  use LiveMapWeb, :live_component
  alias LiveMap.Repo
  alias LiveMapWeb.{NewEventTable, Chart, Loader}
  require Logger

  @impl true
  def mount(socket) do
    socket =
      assign(socket,
        place: nil,
        date: nil,
        spin: true
      )

    {:ok, socket}
  end

  # by default, in Update, all assigns passed are merged into the socket

  attr(:current, :string)
  attr(:user_id, :integer)
  attr(:place, :any)
  attr(:date, :any)

  @impl true
  # render map init
  def render(assigns) do
    IO.puts("map")

    ~H"""
    <div class="flex flex-col justify-center">
      <Loader.display id="map_loader" class="flex justify-center" spin={@spin} />

      <div id="map" phx-hook="ChartHook" phx-update="ignore" phx-target={@myself}></div>

      <NewEventTable.display user_id={@user_id} place={@place} date={@date} />
    </div>
    """
  end

  # append the socket with a new marker to add a new record in the table
  @impl true
  def handle_event("add_point", %{"place" => place}, socket) do
    socket = assign(socket, :place, place)
    {:noreply, socket}
  end

  #  we detected the map was moved, so with new coords, we query the local events
  @impl true
  def handle_event("postgis", %{"movingmap" => moving_map}, socket) do
    # send new map coords once detected for the query table
    %{"distance" => distance, "center" => %{"lat" => lat, "lng" => lng}} = moving_map

    case Repo.features_in_map(lng, lat, String.to_float(distance)) do
      {:error, message} ->
        send(self(), {:push_flash, :postgis, message})
        {:noreply, socket}

      {:ok, rows} ->
        send(self(), {:map_coords, moving_map})
        {:noreply, push_event(socket, "update_map", %{data: List.flatten(rows)})}
    end
  end

  @impl true
  def handle_event("mapoff", %{"id" => id}, socket) do
    send_update(Chart, id: id, spin: true)
    {:noreply, socket}
  end

  @impl true
  def handle_event("mapon", %{"id" => id}, socket) do
    send_update(Chart, id: id, spin: false)
    {:noreply, socket}
  end
end
