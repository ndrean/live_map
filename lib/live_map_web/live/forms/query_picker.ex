defmodule LiveMapWeb.QueryPicker do
  use LiveMapWeb, :live_component
  use Phoenix.Component
  alias LiveMap.QueryPicker
  alias LiveMap.Repo
  require Logger
  import LiveMapWeb.LiveHelpers

  @moduledoc """
  Form with a date as input and saves the completed event
  """

  @menu ["" | ~w(owner pending confired)]

  def mount(socket) do
    {:ok,
     assign(socket,
       changeset: QueryPicker.changeset(%QueryPicker{}),
       status: "",
       users: [],
       start_date: Date.utc_today(),
       end_date: Date.utc_today() |> Date.add(1),
       distance: 0,
       d: 0,
       menu: @menu
     )}
  end

  # render query table once map coords are ready
  def render(%{coords: %{"distance" => distance}} = assigns) do
    assigns = assign(assigns, :distance, parse(distance))
    assigns = assign(assigns, :d, to_km(distance))

    # to default to the user's email, set assigns.user which contains the user's email
    # assigns = assign(assigns, :user, assigns.user)

    ~H"""
    <div>
    <.form :let={f}  for={@changeset} phx-submit="send" phx-change="change"
      phx-target={@myself} id="query_picker"
    >

      <%!-- display the distance on screen--%>
      <p class="text-black font-semibold font-['Roboto'] ml-2">Map radius: <%= @d %> km</p>

      <%!-- passing the value to the formData with no input --%>
      <input type="hidden" value={@distance} name="query_picker[distance]" />

      <%!-- see LiveHelpers for .select and .date --%>
      <div class="flex items-center justify-around mb-2 ml-3">
        <.datalist users={@users}  user={@user} class="form-select w-40" name="query_picker[user]" />
        <.select options={@menu} choice={@status} class="w-500 ml-2 mr-2" name="query_picker[status]"/>
      </div>
      <div class="flex items-center justify-around ml-1 mt-2 mr-1 mb-1">
        <.date date={@start_date} name="query_picker[start_date]" class="w-15 ml-1 rounded-md" label=""/>
          <%= error_tag(f, :start_date) %>
        <button form="query_picker"
          class="px-2 py-2 rounded-md font-['Roboto'] bg-green-500 text-white font-medium text-lg leading-tight uppercase rounded shadow-md hover:bg-green-600 hover:shadow-lg focus:bg-green-600 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-green-700 active:shadow-lg transition duration-150 ease-in-out"
          >Send
        </button>
        <.date date={@end_date} name="query_picker[end_date]" class="w-15 mr-1 rounded-lg" label="" />
          <%= error_tag(f, :end_date) %>
      </div>
      <div class="text-center">
      </div>
    </.form>
    </div>
    """
  end

  # first render without map coords
  def render(assigns) do
    ~H"""
      <div></div>
    """
  end

  # slot(:inner_block)
  attr(:class, :string)
  attr(:name, :string)

  attr(:users, :list)
  attr(:user, :string)

  attr(:target, :string)

  attr(:options, :string)
  attr(:choice, :string)

  attr(:status, :string)

  attr(:date, :any)
  attr(:radius, :float, doc: false)

  def radius(assigns) do
    ~H"""
    <input type="hidden" value={@radius} name={@name} id={@name} />
    """
  end

  def datalist(assigns) do
    ~H"""
      <input list="datalist"
        id="datalist-input"
        name={@name}
        phx-change="search-email"
        phx_debounce="500"
        placeholder="enter an email"
        value={@user}
        class={@class}
        />
      <datalist id="datalist">
          <option :for={user <- @users} value={user}  />
      </datalist>
    """
  end

  def handle_event("change", %{"query_picker" => params}, socket) do
    changeset =
      %QueryPicker{}
      |> QueryPicker.changeset(params)
      |> Map.put(:action, :validate)

    socket =
      socket
      |> assign(:changeset, changeset)
      |> assign(:status, params["status"])
      |> assign(:start_date, params["start_date"])
      |> assign(:end_date, params["end_date"])

    {:noreply, socket}
  end

  # fill in a datalist for users when typing
  # !!!!! USER IS CHANGED HERE
  def handle_event("search-email", %{"query_picker" => %{"user" => string}}, socket) do
    datalist =
      LiveMap.User.search(string)
      |> Enum.map(& &1.email)

    {:noreply, assign(socket, users: datalist, user: string)}
  end

  # given map coords and mandatory dates, returns events to the liveview (send)
  # the query formats the output as [event_id, map_owner, map_demanders_array || map_confirmed_array ]
  # [6, %{"confirmed" => ["demander@gmail.com"], "owner" => ["ownern@yahoo.fr"]},
  # %{"date" => "2022-10-10"}]

  def handle_event("send", %{"query_picker" => form}, socket) do
    changeset = QueryPicker.changeset(%QueryPicker{}, form)

    case changeset.valid? do
      false ->
        Map.put(changeset, :action, :insert)
        {:noreply, assign(socket, changeset: changeset)}

      true ->
        send(self(), {:down_check_all})

        form
        |> to_params(socket.assigns.coords)
        |> process_params(socket)

        # coords = socket.assigns.coords
        # params = to_params(form, coords)
        # process_params(params, socket)

        # reset all hilghlighted events since checkbox defaults to false on refresh (no more in sync)
    end

    # we uncheck all checkboxes with Javascript listener since not everything is updated
    {:noreply, push_event(socket, "clear_boxes", %{})}
  end

  defp process_params(params, socket) do
    Task.Supervisor.async(LiveMap.EventSup, fn ->
      Repo.select_in_map(params)
    end)
    |> then(fn task ->
      case Task.await(task) do
        nil ->
          Logger.warn("Could not retrieve events")
          {:noreply, socket}

        {:error, message} ->
          # send to the LV as flash error message
          send(self(), {:push_flash, :query_picker, message})
          {:noreply, socket}

        result ->
          # send to the LiveView
          send(self(), {:selected_events, result})
          {:noreply, socket}
      end
    end)
  end

  defp to_params(form, coords) do
    %{
      "distance" => d,
      "end_date" => end_date,
      "start_date" => start_date,
      "user" => user,
      "status" => status
    } = form

    {d, _} = Float.parse(d)
    end_date = parse_date(end_date)
    start_date = parse_date(start_date)
    %{"center" => %{"lat" => lat, "lng" => lng}} = coords

    _params = %{
      lat: lat,
      lng: lng,
      distance: d,
      end_date: end_date,
      start_date: start_date,
      user: user,
      status: status
    }
  end

  def parse_date(string_as_date) do
    string_as_date
    |> String.split("-")
    |> Enum.map(&String.to_integer/1)
    |> then(fn [y, m, d] ->
      Date.new!(y, m, d)
    end)
  end

  def parse(d), do: d |> String.to_float() |> round()

  def to_km(d) do
    div1000 = fn x -> x / 1000 end
    d |> parse() |> div1000.() |> round
  end
end
