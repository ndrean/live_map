defmodule LiveMapWeb.Menu do
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  alias LiveMapWeb.Menu

  def display(assigns) do
    ~H"""
    <div>
      <div phx-click={JS.toggle(%JS{}, to: "#menu")} >
        Toggle menu
      </div>
      <div id="menu" >
        <ul  :for={item <- @menu}>
          <Menu.Item.display item={item} />
        </ul>
      </div>
    </div>
    """
  end
end

defmodule LiveMapWeb.Menu.Item do
  use Phoenix.Component

  def display(assigns) do
    ~H"""
    <li class="text-black"><%= @item %></li>
    """
  end
end
