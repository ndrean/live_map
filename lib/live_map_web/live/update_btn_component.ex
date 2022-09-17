defmodule UpdateBtnComponent do
  use Phoenix.Component

  @moduledoc """
  Adds a marker at a given location
  """
  def display(assigns) do
    IO.inspect(self(), label: "render BUTTON - - - - - -")

    ~H"""
    <button id="add-btn" type="button" phx-click="push_marker" phx-value-lat={47.2} phx-value-lng={-1.7}>Add marker</button>
    """
  end
end
