defmodule LiveMapWeb.HeaderSection do
  use LiveMapWeb, :live_component
  import LiveMapWeb.LiveHelpers
  alias LiveMap.ChatSelect

  def mount(socket) do
    {:ok,
     assign(socket,
       changeset: ChatSelect.changeset(%ChatSelect{}),
       list_emails: [],
       nb_users: 1
     )}
  end

  def update(%{current: current} = assigns, socket) do
    IO.puts("update header")
    # in Update, by default, we have the assigns given in the live_component call
    list_emails =
      case assigns.list_ids do
        [] -> []
        list -> Enum.map(list, fn %{user_id: id} -> LiveMap.User.get_by!(:email, id: id) end)
      end

    socket =
      assign(socket,
        emails: list_emails,
        nb_users: list_emails |> length(),
        current: current,
        length: assigns.length
      )

    {:ok, socket}
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
            <.gps_svg/>
          </div>
        </button>
      </div>
      <div class="w-3/4 mt-0 flex justify-center items-center" id="chat">
        <.form id="form-user" for={@changeset} phx-change="change" phx-submit="receiver-email" phx-target={@myself} class="flex">
          <button
            class={["btn gap-1 font-['Roboto'] bg-black border-0", @length  && "pointer-events-none" ]}
            form="form-user"
          >
            <.chat_svg/>
            <div class="badge badge-secondary font-['Roboto']"><%= @nb_users %></div>
          </button>
          <.select options={@emails} choice={@current} name="form-user[email]"
            class="select bg-black w-22 font-['Roboto'] max-w-xs text-xs truncate"
          />
        </.form>
      </div>
    </section>
    """
  end

  def handle_event("change", %{"form-user" => params}, socket) do
    changeset =
      %ChatSelect{}
      |> ChatSelect.changeset(params)
      |> Map.put(:action, :validate)

    case changeset.valid? do
      false ->
        {:noreply, socket}

      true ->
        udpate =
          socket
          |> assign(:changeset, changeset)
          |> assign(:email, params["email"])

        {:noreply, udpate}
    end
  end

  def handle_event("receiver-email", %{"form-user" => %{"email" => email}}, socket) do
    receiver_id = LiveMap.User.get_by!(:id, email: email)
    send(self(), {:receiver_id, receiver_id})
    {:noreply, socket}
  end
end
