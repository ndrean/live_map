defmodule LiveMapWeb.MapLive do
  # use LiveMapWeb, :live_view, layout: {LiveMapWeb.LayoutView, "live.html"}
  use Phoenix.LiveView, layout: {LiveMapWeb.LayoutView, "live.html"}

  @impl true
  def mount(_, _, socket) do
    {:ok, assign(socket, :place, nil)}
  end

  @impl true
  def render(assigns) do
    IO.inspect(assigns, label: "MapLive")

    ~H"""
      <MapLive.LMap.display />
    """
  end

  @impl true
  def handle_event("add_point", %{"place" => place}, socket) do
    {:noreply, assign(socket, :place, place)}
  end
end
