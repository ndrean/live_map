defmodule Table do
  use Phoenix.Component

  def display(assigns) do
    case assigns.place do
      nil ->
        ~H"""
        """

      %{"coords" => []} ->
        ~H"""
        """

      %{"coords" => coords} ->
        ~H"""
        <div>
        <table>
        <caption>Data from user: <%= "user"%></caption>
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
        <p>distance: <%=  if assigns.place, do: assigns.place["distance"], else: 0 %></p>
        </div>
        """
    end
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
    <td><button phx-click="delete_marker" phx-value-id={@row["id"]} type="button"> Delete</button></td>
    </tr>
    """
  end
end

# <tr id={"tr-#{@row["id"]}"} >
# <td><%= @row["lat"] %></td>
# <td><%= @row["lng"] %></td>
# <td><%= @row["name"] %></td>
# </tr>
