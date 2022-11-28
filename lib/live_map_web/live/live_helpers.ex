defmodule LiveMapWeb.LiveHelpers do
  use Phoenix.Component
  import Phoenix.LiveView.Helpers

  alias Phoenix.LiveView.JS

  @moduledoc """
  Function HTML components for LiveView
  """

  def ulist(assigns) do
    ~H"""
    <ul :for={item <- @items}>
      <%!-- <%= if item.a do %> --%>
      <li class="text-black">
        <%= render_slot(@litem, item) %>
      </li>
      <%!-- <% end %> --%>
    </ul>
    """
  end

  def bell_svg(assigns) do
    ~H"""
    <svg
      id="bell_svg"
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      stroke-width="1.5"
      stroke="currentColor"
      class={["w-6 h-6", @class]}
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        d="M14.857 17.082a23.848 23.848 0 005.454-1.31A8.967 8.967 0 0118 9.75v-.7V9A6 6 0 006 9v.75a8.967 8.967 0 01-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 01-5.714 0m5.714 0a3 3 0 11-5.714 0"
      />
    </svg>
    """
  end

  def chat_svg(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      stroke-width="1.5"
      stroke="currentColor"
      class="w-10 h-10 p-1"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        d="M8.625 12a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0H8.25m4.125 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0H12m4.125 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0h-.375M21 12c0 4.556-4.03 8.25-9 8.25a9.764 9.764 0 01-2.555-.337A5.972 5.972 0 015.41 20.97a5.969 5.969 0 01-.474-.065 4.48 4.48 0 00.978-2.025c.09-.457-.133-.901-.467-1.226C3.93 16.178 3 14.189 3 12c0-4.556 4.03-8.25 9-8.25s9 3.694 9 8.25z"
      />
    </svg>
    """
  end

  def gps_svg(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      stroke-width="1.5"
      stroke="currentColor"
      class="w-8 h-8"
    >
      <path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z" />
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z"
      />
    </svg>
    """
  end

  def send_svg(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      stroke-width="1.5"
      stroke="currentColor"
      class="w-6 h-6"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        d="M6 12L3.269 3.126A59.768 59.768 0 0121.485 12 59.77 59.77 0 013.27 20.876L5.999 12zm0 0h7.5"
      />
    </svg>
    """
  end

  def bin_svg(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      stroke-width="1.5"
      stroke="currentColor"
      class="w-6 h-6"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0"
      />
    </svg>
    """
  end

  def spin_svg(assigns) do
    ~H"""
    <div id={@id} class={@class}>
      <svg
        id={"svg-#{@id}"}
        class="inline mr-2 w-8 h-8 text-gray-100 animate-spin dark:text-gray-400 fill-red-600"
        viewBox="0 0 100 101"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path
          d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z"
          fill="currentColor"
        />
        <path
          d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z"
          fill="currentFill"
        />
      </svg>
    </div>
    """
  end

  def search_svg(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      stroke-width="1.5"
      stroke="currentColor"
      class="w-6 h-6"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z"
      />
    </svg>
    """
  end

  def left_message(assigns) do
    ~H"""
    <div class="col-start-1 col-end-10 p-1 rounded-lg">
      <div class="flex flex-row items-center">
        <div class="relative ml-3 text-sm bg-green-200 py-2 px-4 shadow rounded-xl text-black">
          <div class="font-['Roboto'] text-black">
            <%!-- <p><%= @from %> : <span><%= Timex.format!(@time, "%H:%M", :strftime) %></span></p> --%>
            <p><%= @message %></p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def right_message(assigns) do
    nice_time =
      assigns.time
      |> DateTime.from_unix!()
      |> Calendar.strftime("%I:%M:%S")

    # Timex.format!(@nice_time, "%H:%M", :strftime)
    assigns = assign(assigns, :nice_time, nice_time)

    ~H"""
    <div class="col-start-4 col-end-13 p-1 rounded-lg">
      <div class="flex items-center justify-start flex-row-reverse">
        <div class="relative mr-3 text-sm bg-indigo-200 py-2 px-4 shadow rounded-xl">
          <div class="font-['Roboto'] text-black">
            <p class="text-xs text-red-400">
              <%= @from %> : <span><%= @nice_time %></span>
            </p>
            <p><%= @message %></p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a `<select>`HTML tag.

  Mandatory attributes are: `name`, `class`, `options`, `choice`.

  ### Example

      <.select name="query_picker[user]" class=“w-40" options={@some_assigns_list} choice={@final_assign} />

  """

  def select(assigns) do
    ~H"""
    <select id={@name} name={@name} class={@class}>
      <option :for={option <- @options} selected={option == @choice}><%= option %></option>
    </select>
    """
  end

  @doc """
  Input of type date with errors from the changeset.
  Mandatory attributes are: `name`, `class`, `date`:
  """

  def date_err(assigns) do
    attribute = assigns.attribute

    messages =
      assigns.errors
      |> Enum.filter(fn {n, _msg} -> n == attribute end)
      |> Enum.reduce([], fn {_k, {m, _}}, acc -> [m | acc] end)

    assigns = assign(assigns, :messages, messages)

    ~H"""
    <label for={@name}><%= @label %>
      <input type="date" id={@name} name={@name} value={@date} class={[@class, "static"]} />
      <span :for={error <- @messages} class={["text-red-700", @class_err]}><%= error %></span></label>
    """
  end

  def date(assigns) do
    ~H"""
    <label for={@name}>
      <%= @label %>
      <input type="date" id={@name} name={@name} required value={@date} class={[@class, "static"]} />
    </label>
    """
  end

  @doc """
  Renders a live component inside a modal.

  The rendered modal receives a `:return_to` option to properly update
  the URL when the modal is closed.

  ## Examples

      <.modal return_to={Routes.note_index_path(@socket, :index)}>
        <.live_component
          module={InitialWeb.NoteLive.FormComponent}
          id={@note.id || :new}
          title={@page_title}
          action={@live_action}
          return_to={Routes.note_index_path(@socket, :index)}
          note: @note
        />
      </.modal>
  """
  def modal(assigns) do
    assigns = assign_new(assigns, :return_to, fn -> nil end)

    ~H"""
    <div id="modal" class="phx-modal fade-in" phx-remove={hide_modal()}>
      <div
        id="modal-content"
        class="phx-modal-content fade-in-scale"
        phx-click-away={JS.dispatch("click", to: "#close")}
        phx-window-keydown={JS.dispatch("click", to: "#close")}
        phx-key="escape"
      >
        <%= if @return_to do %>
          <%= live_patch("✖",
            to: @return_to,
            id: "close",
            class: "phx-modal-close",
            phx_click: hide_modal()
          ) %>
        <% else %>
          <a id="close" href="#" class="phx-modal-close" phx-click={hide_modal()}>✖</a>
        <% end %>

        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  defp hide_modal(js \\ %JS{}) do
    js
    |> JS.hide(to: "#modal", transition: "fade-out")
    |> JS.hide(to: "#modal-content", transition: "fade-out-scale")
  end
end
