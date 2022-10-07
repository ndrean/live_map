defmodule LiveMapWeb.MapComp do
  use LiveMapWeb, :live_component
  alias LiveMap.Repo
  alias LiveMapWeb.NewEventTable
  require Logger

  @impl true
  def mount(socket) do
    {:ok, assign(socket, place: nil, date: nil)}
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(%{place: %{"coords" => coords}} = assigns) when not is_nil(coords) do
    ~H"""
    <div>
      <div id="map"
        phx-component={2}
        phx-hook="MapHook"
        phx-update="ignore">
        phx-target={@myself}
      </div>
      <NewEventTable.display  user_id={@user_id} user={@current} place={@place} date={@date}/>
    </div>
    """
  end

  # render map init
  def render(assigns) do
    ~H"""
    <div>
      <div id="map"
        phx-component={2}
        phx-hook="MapHook"
        phx-update="ignore">
        phx-target={@myself}
      </div>
      <NewEventTable.display  user={@current} place={@place} date={@date}/>
    </div>
    """
  end

  # append the socket with a new marker
  @impl true
  def handle_event("add_point", %{"place" => place}, socket) do
    {:noreply, assign(socket, :place, place)}
  end

  #  the "moveend" mutates proxy(movingmap) and subscribe triggers pushEvent
  @impl true
  def handle_event("postgis", %{"movingmap" => moving_map}, socket) do
    user_id = socket.assigns.user_id

    [{user_id, now}] = :ets.lookup(:limit_user, user_id)
    time_limit = Time.add(now, 1, :second)

    # send map coords once detected for the query table
    send(self(), {:map_coords, moving_map})

    results =
      case Time.compare(Time.utc_now(), time_limit) do
        :gt ->
          Task.Supervisor.async(LiveMap.EventSup, fn ->
            %{"distance" => distance, "center" => %{"lat" => lat, "lng" => lng}} = moving_map

            Repo.features_in_map(lng, lat, String.to_float(distance))
            |> List.flatten()
          end)
          |> then(fn task ->
            # rate limiter for user
            :ets.insert(:limit_user, {user_id, Time.utc_now()})

            case Task.await(task) do
              nil ->
                Logger.warn("Could not retrieve events")
                nil

              result ->
                result
            end
          end)

        _ ->
          nil
      end

    {:noreply, push_event(socket, "update_map", %{data: results})}
  end
end
