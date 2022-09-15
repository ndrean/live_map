defmodule LMap do
  use Phoenix.Component

  def display(assigns) do
    ~H"""
      <div id="map" phx-hook="MapHook" phx-update="ignore"></div>
    """
  end
end
