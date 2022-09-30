defmodule LiveMapWeb.NewEventTable do
  use Phoenix.Component
  require Logger

  def display(%{place: place} = assigns) when is_nil(place) do
    Logger.debug("Render place nil")

    ~H"""
      <div></div>
    """
  end

  def display(%{place: %{"coords" => []}} = assigns) do
    Logger.debug("Render [] _______")

    ~H"""
      <div></div>
    """
  end

  def display(%{place: %{"coords" => coords}} = assigns) when length(coords) > 0 do
    Logger.debug("Render coords _______")
    # ok event_date, place in assigns
    ~H"""
    <div>
    <div class="flex flex-col">
    <div class="overflow-x-auto sm:-mx-6 lg:-mx-8">
    <div class="py-2 inline-block min-w-full sm:px-6 lg:px-8">
      <div class="overflow-x-auto">
      <table class="min-w-full text-center">
        <caption>Data from user: <%= @user %></caption>
        <thead class="border-b bg-gray-800">
          <tr>
            <th colspan="2" class="text-sm text-white font-medium  px-6 py-2 text-left">
            Coordinates lat/lng</th>
            <th class="text-sm font-medium text-white  px-6 py-2 text-left">
            Found address</th>
            <th class="text-sm font-medium text-white  px-6 py-2 text-left">
            Action</th>
          </tr>
        </thead>
        <tbody>
          <tr class="border-b">
            <%= for coord <- coords do %>
              <.row row={coord} id={"r-#{coord["id"]}"}/>
            <% end %>
          </tr>
        </tbody>
      </table>
      </div>
      </div>
      </div>

    </div>
    <div class="flex items-center justify-center">
      <div class="datepicker relative form-floating mb-3 xl:w-96">
        <span><strong>distance: <%=  assigns.place["distance"] %> km</strong></span>
        <.live_component module={LiveMapWeb.DatePicker} id="date_form" date={@date} place={@place}/>

      </div>
    </div>
    </div>
    """
  end

  def row(assigns) do
    Logger.debug("row")

    ~H"""
    <tr id={"tr-#{@row["id"]}"} >
      <td class="text-sm text-gray-900 font-light px-6 py-2 whitespace-nowrap">
        <button
          class="inline-block px-6 py-2.5 bg-yellow-500 text-white font-medium text-xs leading-tight uppercase rounded shadow-md hover:bg-yellow-600 hover:shadow-lg focus:bg-yellow-600 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-yellow-700 active:shadow-lg transition duration-150 ease-in-out"
          phx-click="delete_marker"
          phx-value-id={@row["id"]}
          type="button">
          Delete
        </button>
      </td>
      <td class="px-6 py-2 whitespace-nowrap text-sm font-medium text-gray-900">
        <%= @row["lat"] %>
      </td>
      <td><%= @row["lng"] %>
      </td>
      <td class="text-sm text-gray-900 font-light px-6 py-2 whitespace-nowrap">
        <%= @row["name"] %>
      </td>
    </tr>
    """
  end
end
