defmodule LiveMapWeb.QueryPicker do
  use LiveMapWeb, :live_component
  use Phoenix.Component
  alias LiveMap.QueryPicker
  alias LiveMap.Repo
  require Logger
  import LiveMapWeb.LiveHelpers
  import LiveMap.Utils

  @moduledoc """
  Form with a date as input and saves the completed event
  """

  @menu ["owner", "pending", "confirmed"]

  # def mount(socket) do
  #   {:ok,
  #    assign(socket,
  #      changeset: QueryPicker.changeset(%QueryPicker{})
  #      #  status: "",
  #      #  users: [],
  #      #  start_date: Date.utc_today(),
  #      #  end_date: Date.utc_today() |> Date.add(get_default_end_date()),
  #      #  distance: 0,
  #      #  d: 0,
  #      #  menu: @menu
  #    )}
  # end

  def update(%{coords: coords, current: current, user_id: user_id} = _assigns, socket) do
    # received from live_component call
    IO.puts("update query picker")

    update =
      assign(socket,
        current: current,
        user_id: user_id,
        coords: coords,
        start_date: Date.utc_today(),
        end_date: Date.utc_today() |> Date.add(get_default_end_date()),
        distance: 0,
        d: 0,
        menu: @menu,
        status: "",
        users: [],
        changeset:
          QueryPicker.changeset(%QueryPicker{}, %{
            start_date: Date.utc_today(),
            end_date: Date.utc_today() |> Date.add(get_default_end_date())
          })
      )

    {:ok, update}
  end

  # attr(:errors, :list)
  # attr(:class_err, :string)
  # attr(:date, :string)
  # attr(:label, :string)

  # render query table once map coords are ready
  def render(%{coords: %{"distance" => distance}} = assigns) do
    assigns = assign(assigns, :distance, string_to_float(distance))
    assigns = assign(assigns, :d, to_km(distance))

    ~H"""
    <div>
      <.form
        :let={_f}
        for={@changeset}
        phx-submit="send"
        phx-change="change"
        phx-target={@myself}
        id="query_picker"
      >
        <%!-- display the distance on screen--%>
        <div class="flex justify-center">
          <span class="text-black font-semibold font-['Roboto'] ml-2">Map radius: <%= @d %> km</span>
        </div>

        <%!-- passing the value to the formData with no input --%>
        <input type="hidden" value={@distance} name="query_picker[distance]" />
        <input type="hidden" value={@current} name="query_picker[user]" />

        <%!-- <div class="flex items-center justify-around mb-2 ml-3"> --%>
        <%!-- <.datalist users={@users}  user={@user} class="form-select w-40" name="query_picker[user]" /> --%>
        <%!-- <.select options={@menu} choice={@status} class="w-500 ml-2 mr-2" name="query_picker[status]"/> --%>
        <input type="hidden" value={@status} name="query_picker[status]" />

        <%!-- </div> --%>
        <div class="flex items-center justify-around content-evenly ml-1 mt-2 mr-1 mb-1">
          <.date
            date={@start_date}
            name="query_picker[start_date]"
            class="w-15 m-1 rounded-md"
            label=""
          />
          <button
            form="query_picker"
            class="px-2 py-2 rounded-md font-['Roboto'] bg-indigo-500 text-white font-medium text-lg leading-tight uppercase  shadow-md hover:bg-indigo-600 hover:shadow-lg focus:bg-indigo-600 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-indigo--700 active:shadow-lg transition duration-150 ease-in-out"
          >
            <.search_svg />
          </button>

          <.date_err
            date={@end_date}
            name="query_picker[end_date]"
            label=""
            class="w-15 m-1 rounded-md"
            class_err="mt-1"
            errors={@changeset.errors}
            attrib={:end_date}
          />
        </div>
        <div class="text-center"></div>
      </.form>
    </div>
    """
  end

  # first render without map coords
  def render(assigns) do
    IO.puts("render query dates all empty")

    ~H"""
    <div></div>
    """
  end

  attr(:name, :string)

  # attr(:users, :list)
  # attr(:user, :string)

  # attr(:target, :string)

  # attr(:options, :list)
  # attr(:choice, :string)

  # attr(:status, :string)

  # attr(:date, :any)
  # attr(:radius, :float, doc: false)

  def radius(assigns) do
    ~H"""
    <input type="hidden" value={@radius} name={@name} id={@name} />
    """
  end

  attr(:class, :string)
  attr(:name, :string)

  def datalist(assigns) do
    ~H"""
    <input
      list="datalist"
      id="datalist-input"
      name={@name}
      phx-change="search-email"
      phx_debounce="500"
      placeholder="enter an email"
      value={@user}
      class={@class}
    />
    <datalist id="datalist">
      <option :for={user <- @users} value={user}><%= user %></option>
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
      # |> assign(:status, params["status"])
      |> assign(:status, "")
      |> assign(:start_date, params["start_date"])
      |> assign(:end_date, params["end_date"])

    {:noreply, socket}
  end

  # fill in a datalist for users when typing
  # !!!!! USER IS CHANGED HERE
  # def handle_event("search-email", %{"query_picker" => %{"user" => string}}, socket) do
  #   datalist =
  #     LiveMap.User.search(string)
  #     |> Enum.map(& &1.email)

  #   {:noreply, assign(socket, users: datalist, user: string)}
  # end

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
        # remove all highlighted events
        send(self(), {:down_check_all})

        form
        |> to_params(socket.assigns.coords)
        |> process_params(socket)
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

        # send to the LV as flash error message
        {:error, message} ->
          send(self(), {:push_flash, :query_picker, message})
          {:noreply, socket}

        # send to the LiveView
        result ->
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

    # end_date = parse_date(end_date)
    # start_date = parse_date(start_date)
    %{"center" => %{"lat" => lat, "lng" => lng}} = coords

    _params = %{
      lat: lat,
      lng: lng,
      distance: string_to_float(d),
      end_date: parse_date(end_date),
      start_date: parse_date(start_date),
      user: user,
      status: status
    }
  end

  defp get_default_end_date() do
    Application.get_env(:live_map, :default_days) || System.get_env("DEFAULT_TIME_RANGE")
  end
end
