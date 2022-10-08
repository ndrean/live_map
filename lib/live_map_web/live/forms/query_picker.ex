defmodule LiveMapWeb.QueryPicker do
  use LiveMapWeb, :live_component
  use Phoenix.HTML
  # import Ecto.Query
  alias LiveMap.QueryPicker
  alias LiveMap.Repo
  require Logger

  def mount(socket) do
    {:ok,
     assign(socket,
       changeset: QueryPicker.changeset(%{}),
       status: ["all", "pending", "confirmed"],
       users: [],
       user: nil,
       users: []
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  # render query table with map coords
  def render(%{coords: %{"distance" => distance}} = assigns) do
    assigns = assign(assigns, distance: parse(distance))

    # phx-change="search"
    ~H"""
    <div>
    <.form :let={f}  for={@changeset}
      phx-submit="send"
      phx-target={@myself}
      id="query_picker">

      <%= number_input(f, :distance, id: "distance", value: @distance) %><span>km</span>

      <%= text_input(f, :user, phx_change: "search", phx_target: @myself, phx_debounce: "500", list: "datalist", placeholder: "enter an email") %>
      <%= error_tag(f, :user) %>
      <%= datalist_input(id: "datalist") do %>
        <%= for user <- @users do %>
          <%= option_input(user) %>
        <% end %>
      <% end %>

      <%= select(f, :status, @status) %>
      <%= error_tag(f, :status) %>

      <%= date_input(f, :start_date, id: "start_date", ) %>
      <%= error_tag(f, :start_date) %>
      <%= date_input(f, :end_date, id: "end_date") %>
      <%= error_tag(f, :end_date) %>
      <%= submit "submit",
      class: "inline-block mr-60 px-6 py-2.5 bg-green-500 text-white font-medium text-xs leading-tight uppercase rounded shadow-md hover:bg-green-600 hover:shadow-lg focus:bg-green-600 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-green-700 active:shadow-lg transition duration-150 ease-in-out"
      %>
    </.form>
    </div>
    """
  end

  # render init query table without map coords
  def render(assigns) do
    ~H"""
      <div></div>
    """
  end

  def handle_event("search", %{"query_picker" => %{"user" => string}}, socket) do
    datalist = LiveMap.User.search(string) |> Enum.map(& &1.email)
    {:noreply, assign(socket, users: datalist)}
  end

  # def handle_event("validate", %{"query_picker" => form}, socket) do
  #   changeset =
  #     QueryPicker.changeset(form)
  #     |> Map.put(:action, :insert)

  #   {:noreply, assign(socket, changeset: changeset)}
  # end

  def handle_event("send", %{"query_picker" => form}, socket) do
    changeset = QueryPicker.changeset(form)

    # reset all hilghlighted events since checkbox defaults to false on refresh (no more in sync)
    send(self(), {:down_check_all})

    case changeset.valid? do
      false ->
        changeset |> Map.put(:action, :insert)
        {:noreply, assign(socket, changeset: changeset)}

      true ->
        process_params(form, socket.assigns.coords)
    end

    {:noreply, socket}
  end

  defp process_params(form, coords) do
    params = extract_params_for_query(form, coords)

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

  defp extract_params_for_query(form, coords) do
    %{
      "distance" => d,
      "end_date" => end_date,
      "start_date" => start_date
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
      start_date: start_date
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

  defp parse(distance), do: distance |> String.to_float() |> round
end
