defmodule LiveMapWeb.MapLive do
  use Phoenix.LiveView
  alias LiveMap.{Repo, User, Event}
  # , layout: {LiveMapWeb.LayoutView, "live.html"}

  @impl true
  def mount(_, %{"email" => email} = _session, socket) do
    socket = assign(socket, current: email)
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
    <.live_component module={MapComp} id="map"  current={@current}/>
    </div>
    """
  end

  @impl true
  def handle_event("delete_marker", %{"id" => id}, socket) do
    {:noreply, push_event(socket, "delete_marker", %{id: id})}
  end

  def handle_event(
        "save_event",
        %{"place" => %{"coords" => places, "distance" => distance}},
        socket
      ) do
    [
      %{"lat" => lat1, "lng" => lng1, "name" => ad1},
      %{"lat" => lat2, "lng" => lng2, "name" => ad2}
    ] = places

    conv = fn s -> String.to_float(s) end

    Event.new(%{
      user_id: Repo.get_by(User, email: socket.assigns.current).id,
      coordinates: %Geo.LineString{
        coordinates: [{conv.(lng2), conv.(lat2)}, {conv.(lng1), conv.(lat1)}],
        srid: 4326
      },
      distance: conv.(distance),
      ad1: ad1,
      ad2: ad2,
      date: Date.utc_today()
    })

    socket |> put_flash(:info, "Your new event has been saved")
    {:noreply, push_event(socket, "clear_event", %{})}
  end

  @impl true
  # def handle_info(%{data: data}, socket) do
  #   IO.puts("info_____________________________")
  #   {:noreply, push_event(socket, "init", %{data: data})}
  # end
end
