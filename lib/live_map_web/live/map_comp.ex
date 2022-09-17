defmodule MapComp do
  # use LiveMapWeb, :live_component
  use LiveMapWeb, :live_component
  # use Phoenix.LiveComponent

  @impl true
  def mount(socket) do
    # socket = assign(socket, current: email, place: nil, eventsparams: nil)
    IO.inspect(self(), label: "Mount Map ________________")
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    IO.inspect(self(), label: "UPDATE")
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    IO.puts("Render Map____________________")

    ~H"""
    <div id="map"
    phx-hook="MapHook"
    phx-update="ignore">
    </div>
    """

    # Phoenix.View.render(LiveMapWeb.MapView, "map.html", assigns)
  end

  # phx-target={@myself}

  @impl true
  def handle_event("add_point", %{"place" => place}, socket) do
    # IO.inspect(place, label: "add_point")
    {:noreply, assign(socket, :place, place)}
  end

  @impl true
  def handle_event("postgis", %{"eventsparams" => events_params}, socket) do
    IO.inspect(events_params, label: "POSTGIS")
    {:noreply, assign(socket, :events_params, events_params)}
  end

  def handle_event("new_event", %{"newEvent" => new_event}, socket) do
    IO.inspect(new_event, label: "new_event_________________________")
    {:noreply, assign(socket, :new_event, new_event)}
  end

  @impl true
  def handle_event("delete_marker", %{"id" => id}, socket) do
    IO.inspect(id, label: "delete")
    {:noreply, push_event(socket, "delete_marker", %{id: id})}
  end
end
