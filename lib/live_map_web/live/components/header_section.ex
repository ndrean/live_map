defmodule LiveMapWeb.HeaderSection do
  use LiveMapWeb, :live_component
  import LiveMapWeb.LiveHelpers
  alias LiveMapWeb.Endpoint
  alias LiveMap.{ChatSelect, User}
  # alias Phoenix.LiveView.JS
  require Logger

  @moduledoc """
  Header, navigate between Map and Chat
  """
  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       changeset: ChatSelect.changeset(%ChatSelect{}),
       newclass: ""
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="flex mb-4 mt-4 justify-center bg-black" id="header">
      <div class="w-1/4 mt-0 flex flex-wrap items-center justify-center" id="geolocation">
        <button
          class="btn gap-1 font-['Roboto'] bg-black border-0"
          phx-click="switch_map"
          phx-target={@myself}
        >
          GPS
          <div class="badge border-0 bg-black">
            <.gps_svg />
          </div>
        </button>
      </div>
      <div class="w-3/4 mt-0 flex justify-center items-center">
        <.form
          id="form-user"
          for={@changeset}
          phx-change="change"
          phx-target={@myself}
          phx-submit="notify"
          class="flex"
          phx-hook="Notify"
        >
          <button
            id="header-chat"
            class={[
              "btn gap-1 font-['Roboto'] bg-black border-0 cursor-pointer",
              length(@p_users) == 1 && "pointer-events-none"
            ]}
          >
            <.bell_svg class={@newclass} />
            <div class="badge badge-secondary font-['Roboto']"><%= length(@p_users) %></div>
          </button>
          <.select
            options={@p_users}
            choice={@current}
            name="form-user[email]"
            class="select bg-black w-22 font-['Roboto'] max-w-xs text-xs truncate"
          />
        </.form>
      </div>
    </section>
    """
  end

  @impl true
  def handle_event("switch_map", _, socket) do
    send(self(), "switch_map")
    {:noreply, socket}
  end

  def handle_event("change", %{"form-user" => %{"email" => email} = params}, socket) do
    changeset =
      %ChatSelect{}
      |> ChatSelect.changeset(params)
      |> Map.put(:action, :validate)

    case changeset.valid? do
      false ->
        Logger.info("msg not valid")
        {:noreply, socket}

      true ->
        send(self(), {:change_receiver_email, email})

        {:noreply,
         socket
         |> assign(:changeset, changeset)
         |> assign(:email, email)}
    end
  end


  def handle_event(
        "notify",
        %{"form-user" => %{"email" => email}},
        %{assigns: %{channel: channel, current: current}} = socket
      ) do
    receiver_id = User.get_by!(:id, email: email)

    Endpoint.broadcast!(
      channel,
      "toggle_bell",
      {current, email, receiver_id, "text-indigo-500 animate-bounce"}
    )

    send(self(), "switch_chat")
    {:noreply, socket}
  end
end
