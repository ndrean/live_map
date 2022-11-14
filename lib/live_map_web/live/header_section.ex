defmodule LiveMapWeb.HeaderSection do
  use LiveMapWeb, :live_component
  import LiveMapWeb.LiveHelpers
  alias LiveMap.ChatSelect

  def mount(socket) do
    {:ok,
     assign(socket,
       class: "",
       emails: [],
       user: "",
       nb_users: 1,
       name: "",
       changeset: ChatSelect.changeset(%ChatSelect{})
     )}
  end

  def update(assigns, socket) do
    # IO.inspect(assigns, label: "update")

    list_emails =
      case assigns.emails do
        [] -> []
        list -> Enum.map(list, fn %{user_id: id} -> LiveMap.User.email(id) end)
      end

    socket =
      socket
      |> assign(:emails, list_emails)
      |> assign(:nb_users, list_emails |> length())
      |> assign(:user, assigns.user)

    # |> assign(:user_email, assigns.user_email)
    # |> assign(:nb_users, assigns.nb_users)

    {:ok, socket}
  end

  attr(:options, :list)
  attr(:choice, :string)
  attr(:name, :string)

  def render(assigns) do
    # IO.inspect(assigns, label: "assigns render")

    ~H"""
    <section class="flex mb-4 mt-4 justify-center bg-black" >
      <div class="w-1/4 mt-0 flex flex-wrap items-center justify-center" id="geolocation">
        <button class="btn gap-1 font-['Roboto'] bg-black border-0">
          GPS
          <div class="badge border-0 bg-black">
            <.gps_svg/>
          </div>
        </button>
      </div>
      <div class="w-3/4 mt-0 flex justify-center items-center" id="chat">
        <.form id="form-chat" for={@changeset} phx-change="change" phx-submit="send-email" phx-target={@myself} class="flex">
          <button class="btn gap-1 font-['Roboto'] bg-black border-0" form="form-chat">
            <.chat_svg/>
            <div class="badge badge-secondary font-['Roboto']"><%= @nb_users %></div>
          </button>
          <.select options={@emails} choice={@user} name="form-chat[name]"
            class="select bg-black w-22 font-['Roboto'] max-w-xs text-xs truncate"
          />
        </.form>
      </div>
    </section>
    """
  end

  def handle_event("change", %{"form-chat" => params}, socket) do
    # IO.inspect(params, label: "change")

    changeset =
      %ChatSelect{}
      |> ChatSelect.changeset(params)
      |> Map.put(:action, :validate)

    socket =
      socket
      |> assign(:changeset, changeset)
      |> assign(:name, params["name"])

    {:noreply, socket}
  end

  def handle_event("send-email", %{"form-chat" => %{"name" => name}}, socket) do
    {:noreply, socket |> assign(chat: %{user: socket.assigns.user, with: name})}
  end
end
