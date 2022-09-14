defmodule MapLive.LMap do
  use Phoenix.Component

  def display(assigns) do
    IO.inspect(assigns, label: "LMAP")

    ~H"""
      <div class="flex">
        <div id="map" phx-hook="MapHook" phx-udpate="ignore"></div>
      </div>
    """
  end
end
