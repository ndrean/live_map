defmodule LiveMapWeb.Loader do
  use Phoenix.Component
  import LiveMapWeb.LiveHelpers

  def display(assigns) do
    ~H"""
    <div>
      <.spin_svg :if={@spin} id={"svg-#{@id}"} class={@class} />
    </div>
    """
  end
end
