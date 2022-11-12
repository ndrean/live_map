defmodule LiveMapWeb.MapLoader do
  use Phoenix.Component
  import LiveMapWeb.LiveHelpers

  def display(assigns) do
    ~H"""
    <div >
      <.spin_svg id={"svg-#{@id}"}  class={@class} :if={@spin}/>
    </div>
    """
  end
end
