defmodule LiveMapWeb.NewEventTable do
  use Phoenix.LiveComponent

  def render(%{place: place} = assigns) when is_nil(place) do
    ~H"""
      <div></div>
    """
  end

  def render(%{place: %{"coords" => []}} = assigns) do
    ~H"""
      <div></div>
    """
  end

  def render(%{place: %{"coords" => coords}} = assigns) when length(coords) > 0 do
    ~H"""
    <div>
      <table>
      <caption>Data from user: <%= @user %></caption>
      <thead>
        <tr>
          <th colspan="2">Coordinates lat/lng</th>
          <th>Found address</th>
          <th>Action</th>
        </tr>
      </thead>
      <tbody>
      <tr>
      <%= for coord <- coords do %>
        <Row.display row={coord} id={"r-#{coord["id"]}"}/>
      <% end %>
      </tr>
      </tbody>
      </table>
      <p>distance: <%=   assigns.place["distance"] %></p>
    </div>
    """
  end
end

defmodule Row do
  use Phoenix.Component

  def display(assigns) do
    IO.puts("row")

    ~H"""
    <tr id={"tr-#{@row["id"]}"} >
      <td><%= @row["lat"] %></td>
      <td><%= @row["lng"] %></td>
      <td><%= @row["name"] %></td>
      <td>
        <button
          phx-click="delete_marker"
          phx-value-id={@row["id"]}
          type="button">
            Delete
        </button>
      </td>
    </tr>
    """
  end
end
