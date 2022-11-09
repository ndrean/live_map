defmodule LiveMapWeb.NewEventTable do
  use Phoenix.Component
  alias LiveMapWeb.NewEvent
  import LiveMapWeb.LiveHelpers
  require Logger

  attr :place, :map
  attr :user, :string
  attr :date, :any
  attr :user_id, :integer

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

  def display(%{place: %{"coords" => coords, "distance" => distance}} = assigns)
      when length(coords) > 0 do
    assigns =
      assigns
      |> assign(coords: coords, distance: distance)

    ~H"""
    <div>
      <p class="text-center w-full"><strong>distance: <%=  @distance %> km</strong></p>

      <div class="overflow-x-auto">
        <table class="table table-compact w-full">
          <caption class="text-sm text-left">You are editing a new event; select two points, set a future date and save.</caption>
          <thead class="border-b bg-gray-800">
            <tr>
              <th class="text-sm font-medium text-center text-white  px-3 py-2 text-left">
                Action
              </th>
              <th class="truncate text-ellipsis text-sm font-medium text-left text-white  px-1 py-2 text-left">
                Found address
              </th>
            </tr>
          </thead>
          <tbody>
            <tr class="border-b" :for={coord <- @coords}>
                <%# for coord <- @coords do %>
              <.row row={coord} id={"r-#{coord["id"]}"}/>
                <%# end %>
            </tr>
          </tbody>
        </table>
      </div>

      <.live_component module={NewEvent} id="date_form"
        user={@user} date={@date} place={@place} user_id={@user_id}
        class="flex flex-row w-full justify-around space-x-2 px-2"
      />
    </div>
    """
  end

  def row(%{row: %{"id" => id, "name" => name}} = assigns) do
    assigns = assign(assigns, name: name, id: id)

    ~H"""
    <tr id={"tr-#{@id}"} >
    <%!-- <td class="text-sm text-gray-900 font-light px-2 py-2 whitespace-nowrap"> --%>
      <td>
        <button
          class="inline-block px-2 py-2.5 bg-yellow-500 text-white font-medium text-xs leading-tight uppercase rounded shadow-md hover:bg-yellow-600 hover:shadow-lg focus:bg-yellow-600 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-yellow-700 active:shadow-lg transition duration-150 ease-in-out"
          phx-click="delete_marker"
          phx-value-id={@id}
          type="button"
        >
          <.bin_svg/>
        </button>
      </td>
      <td class="text-sm text-white font-light px-2 py-2 whitespace-nowrap">
        <%= @name %>
      </td>
    </tr>
    """
  end
end
