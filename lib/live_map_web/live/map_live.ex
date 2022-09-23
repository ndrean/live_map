defmodule LiveMapWeb.MapLive do
  # use LiveMapWeb, :live_view
  use Phoenix.LiveView
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
    IO.inspect(id, label: "delete")
    {:noreply, push_event(socket, "delete_marker", %{id: id})}
  end

  def handle_event("save_event", _, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{new_event: new_event}, socket) do
    IO.inspect(new_event, label: "in parent LiveView ********************************")
    {:noreply, socket}
  end

  def handle_info(%{data: data}, socket) do
    IO.puts("info_____________________________")
    {:noreply, push_event(socket, "init", %{data: data})}
  end
end
