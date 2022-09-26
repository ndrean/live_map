defmodule MapComp do
  # use LiveMapWeb, :live_component
  use Phoenix.LiveComponent
  require Logger

  @impl true
  def mount(socket) do
    IO.puts("MOUNT MAP_____________________________")

    # socket =
    #   socket
    #   |> assign(:place, nil)
    #   |> assign(:event_date, nil)
    #   |> assign(:changeset, LiveMap.EventDate)

    {:ok, assign(socket, place: nil, date: nil)}
  end

  @impl true
  def update(assigns, socket) do
    IO.puts("UPDATE___________________")
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    IO.puts("RENDER MAP_____________________________")

    ~H"""
    <div>
      <div id="map"
        phx-component={2}
        phx-hook="MapHook"
        phx-update="ignore">
        phx-target={@myself}
      </div>
      <LiveMapWeb.NewEventTable.display  user={@current} place={@place} date={@date}/>
    </div>
    """
  end

  # append the socket with a new market
  @impl true
  def handle_event("add_point", %{"place" => place}, socket) do
    {:noreply, assign(socket, :place, place)}
  end

  # def handle_info({:newintown, %{"place" => place, "date" => date}}, socket) do
  #   IO.inspect(socket.assigns, label: "uuuuuuuuuuuuu----------------")
  #   {:noreply, socket}
  # end

  #  the "moveend" mutates proxy(movingmap) and subscribe triggers pushEvent
  @impl true
  def handle_event("postgis", %{"movingmap" => moving_map}, socket) do
    task =
      Task.Supervisor.async(LiveMap.TSup, fn ->
        %{"distance" => distance, "center" => %{"lat" => lat, "lng" => lng}} = moving_map

        LiveMap.Repo.features_in_map(lng, lat, String.to_float(distance))
        |> List.flatten()
      end)

    results =
      case Task.await(task) do
        nil ->
          Logger.warn("Could not retrieve events")
          nil

        results ->
          results
      end

    {:noreply, push_event(socket, "update_map", %{data: results})}
  end

  # new marker -> update local socket for table
  # @impl true
  # def handle_event("new_event", %{"newEvent" => new_event}, socket) do
  #   IO.puts("new marker-----------------")
  #   send(self(), %{new_event: new_event})
  #   {:noreply, assign(socket, :new_event, new_event)}
  # end
end
