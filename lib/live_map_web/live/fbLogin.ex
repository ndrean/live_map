defmodule LiveMapWeb.FbLogin do
  use LiveMapWeb, :live_view

  def render(assigns) do
    ~H"""
      <button phx-hook="fbLoginHook" id="fbhook" type="button" phx-click="login"> FB Hook</button>
    """
  end

  def handle_event("click", %{}, socket) do
    {:noreply, push_event(socket, "login", %{})}
  end
end
