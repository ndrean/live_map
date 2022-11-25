defmodule LiveMapWeb.HeaderSection do
  use LiveMapWeb, :live_component
  import LiveMapWeb.LiveHelpers
  alias LiveMapWeb.HeaderSection
  alias LiveMap.ChatSelect
  # alias Phoenix.LiveView.JS

  def mount(socket) do
    {:ok,
     assign(socket,
       changeset: ChatSelect.changeset(%ChatSelect{}),
       newclass: ""
     )}
  end

  attr(:options, :list)
  attr(:choice, :string)
  attr(:name, :string)
  attr(:entries, :list, default: [])

  def render(assigns) do
    IO.puts("render header")

    ~H"""
    <section class="flex mb-4 mt-4 justify-center bg-black" id="header">
      <div class="w-1/4 mt-0 flex flex-wrap items-center justify-center" id="geolocation">
        <button class="btn gap-1 font-['Roboto'] bg-black border-0">
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
            <%!-- form="form-user" --%>
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

  def handle_event("change", %{"form-user" => %{"email" => email} = params}, socket) do
    changeset =
      %ChatSelect{}
      |> ChatSelect.changeset(params)
      |> Map.put(:action, :validate)

    case changeset.valid? do
      false ->
        IO.puts("msg not valid")
        {:noreply, socket}

      true ->
        send(self(), {:change_receiver_email, email})

        udpate =
          socket
          |> assign(:changeset, changeset)
          |> assign(:email, email)

        {:noreply, udpate}
    end
  end

  def handle_event("change", _, socket) do
    {:noreply, socket}
  end

  def handle_event("notify", %{"form-user" => %{"email" => email}}, socket) do
    receiver_id = LiveMap.User.get_by!(:id, email: email)
    # send_update(pid, HeaderSection,
    #   id: "header",
    #   newclass: "text-indigo-500 animate-bounce",
    #   receiver: email
    # )
    LiveMapWeb.Endpoint.broadcast!(
      socket.assigns.channel,
      "toggle_bell",
      {socket.assigns.current, email, receiver_id, "text-indigo-500 animate-bounce"}
    )

    # {:noreply, socket}
    IO.inspect("#{email}, #{socket.assigns.current}, #{receiver_id}")

    {:noreply, socket}
    # {:noreply,
    #  push_event(socket, "notify", %{
    #    to: email,
    #    from: socket.assigns.current,
    #    receiver: receiver_id
    #  })}
  end
end
