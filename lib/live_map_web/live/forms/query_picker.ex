defmodule LiveMapWeb.QueryPicker do
  use LiveMapWeb, :live_component
  use Phoenix.Component
  alias LiveMap.QueryPicker
  alias LiveMap.Repo
  require Logger

  def mount(socket) do
    {:ok,
     assign(socket,
       changeset: QueryPicker.changeset(%QueryPicker{}),
       status: ["all", "pending", "confirmed"],
       users: [],
       select: "all"
     )}
  end

  # def update(assigns, socket) do
  #   {:ok, assign(socket, assigns)}
  # end

  # render query table once map coords are ready
  def render(%{coords: %{"distance" => distance}} = assigns) do
    assigns = assign(assigns, distance: parse(distance))
    assigns = assign(assigns, :d, to_km(assigns.distance))
    assigns = assign(assigns, :user, assigns.user)
    assigns = assign(assigns, :select, assigns.select)

    ~H"""
    <div>
    <.form :let={f}  for={@changeset}
      phx-submit="send"
      phx-change="change"
      phx-target={@myself}
      id="query_picker"
      >

      <span>Map radius: <%= @d %> km</span>
      <%= hidden_input(f, :distance, id: "distance", value: @distance) %>

      <br/>

      <%# text_input(f, :user, phx_change: "search-email", phx_target: @myself, phx_debounce: "500", list: "datalist", placeholder: "enter an email") %>
      <%# error_tag(f, :user) %>
      <%# datalist_input(id: "datalist") do %>
        <%#for user <- @users do %>
          <%# option_input(user) %>
        <%# end %>
      <%# end %>

      <div class="flex items-center justify-around mb-2 ml-3">
        <.datalist users={@users} target={@myself} user={@user}></.datalist>
        <button></button>
        <.select status={@status} select={@select}></.select>
      </div>
      <div class="flex items-center justify-around ml-3 mt-2">
        <%= date_input(f, :start_date, class: "w-60" ) %>
        <%= error_tag(f, :start_date) %>
        <button form="query_picker"
          class="px-2 py-2 bg-green-500 text-white font-medium text-lg leading-tight uppercase rounded shadow-md hover:bg-green-600 hover:shadow-lg focus:bg-green-600 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-green-700 active:shadow-lg transition duration-150 ease-in-out"
        >Send
        </button>
        <%= date_input(f, :end_date, class: "w-60") %>
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

  slot(:inner_block, required: true)
  attr(:users, :list)
  attr(:user, :string)
  attr(:target, :string)
  attr(:status, :list)
  attr(:select, :string)

  def datalist(assigns) do
    ~H"""
      <input list="datalist"
        id="datalist-input"
        name="query_picker[user]"
        phx-change="search-email"
        phx-target={@target}
        phx_debounce="500"
        placeholder="enter an email"
        value={@user}
        class="form-select w-40"
        />
      <datalist id="datalist">
          <option :for={user <- @users} value={user}  />
      </datalist>
    """
  end

  def select(assigns) do
    ~H"""
      <select id="select" name="query_picker[status]" class="w-50 ml-2 mr-2">
        <option :for={status <- @status} selected={status == @select}><%= status %></option>
      </select>
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
      |> assign(:select, params["status"])

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
        coords = socket.assigns.coords
        params = to_params(form, coords)

        # reset all hilghlighted events since checkbox defaults to false on refresh (no more in sync)
        send(self(), {:down_check_all})
        process_params(params)
    end

    # we uncheck all checkboxes with Javacsript listener since not everything is updated
    {:noreply, push_event(socket, "clear_boxes", %{})}
  end

  defp process_params(params) do
    Task.Supervisor.async(LiveMap.EventSup, fn ->
      Repo.select_in_map(params)
    end)
    |> then(fn task ->
      #   #   # rate limiter for user
      #   #   IO.inspect(Time.utc_now())
      # :ets.insert(:limit_user, {user_id, Time.utc_now()})

      case Task.await(task) do
        nil ->
          Logger.warn("Could not retrieve events")
          nil

        result ->
          # send to the LiveView
          send(self(), {:selected_events, result})
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

  defp parse_date(string_as_date) do
    string_as_date
    |> String.split("-")
    |> Enum.map(&String.to_integer/1)
    |> then(fn [y, m, d] ->
      Date.new!(y, m, d)
    end)
  end

  defp parse(d), do: d |> String.to_float() |> round()

  defp to_km(d) do
    div1000 = fn x -> x / 1000 end
    d |> div1000.() |> round
  end
end
