defmodule LiveMapWeb.NewEventTable do
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  def display(%{place: place} = assigns) when is_nil(place) do
    ~H"""
      <div></div>
    """
  end

  def display(%{place: %{"coords" => []}} = assigns) do
    ~H"""
      <div></div>
    """
  end

  def display(%{place: %{"coords" => coords}} = assigns) when length(coords) > 0 do
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
    <.row row={coord} id={"r-#{coord["id"]}"}/>
    <% end %>
    </tr>
    </tbody>
    </table>
    <p class="save-row">
      <span><strong>distance: <%=   assigns.place["distance"] %></strong></span>
      <button
        disabled={length(coords)<2}
        phx-click={JS.push("save_event", value: %{place: assigns.place})}
        type="button">Update
      </button>
    </p>
    </div>
    """
  end

  # phx-value={@assigns.place}

  def row(assigns) do
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
