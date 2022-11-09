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
         <%=   render_slot(@litem, item)%>
        </li>
      <%!-- <% end %> --%>
    </ul>
    """
  end

  def chat_svg(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-12 h-12 p-1">
      <path stroke-linecap="round" stroke-linejoin="round" d="M8.625 12a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0H8.25m4.125 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0H12m4.125 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0h-.375M21 12c0 4.556-4.03 8.25-9 8.25a9.764 9.764 0 01-2.555-.337A5.972 5.972 0 015.41 20.97a5.969 5.969 0 01-.474-.065 4.48 4.48 0 00.978-2.025c.09-.457-.133-.901-.467-1.226C3.93 16.178 3 14.189 3 12c0-4.556 4.03-8.25 9-8.25s9 3.694 9 8.25z" />
    </svg>
    """
  end

  def gps_svg(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-8 h-8">
      <path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z" />
      <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z" />
    </svg>
    """
  end

  def send_svg(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
      <path stroke-linecap="round" stroke-linejoin="round" d="M6 12L3.269 3.126A59.768 59.768 0 0121.485 12 59.77 59.77 0 013.27 20.876L5.999 12zm0 0h7.5" />
    </svg>
    """
  end

  def bin_svg(assigns) do
    ~H"""
     <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
      <path stroke-linecap="round" stroke-linejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" />
    </svg>
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
      <select id={"status-#{@name}"} name={@name} class={@class}>
        <option :for={option <- @options} selected={option == @choice}><%= option%></option>
      </select>
    """
  end

  @doc """
  Input of type date.

  Mandatory attributes are: `name`, `class`, `date`:

  ### Example:

      <.date date={@start_date} name="query_picker[start_date]" class="w-60"/>

  """

  def date_err(assigns) do
    messages =
      assigns.errors
      |> Enum.reduce([], fn {_field, {msg, _}}, acc -> [msg | acc] end)

    assigns = assign(assigns, :messages, messages)

    ~H"""
    <label for={@name}>
      <input type="date" id={@name} name={@name}  value={@date} class={[@class]}/>
      <span class={["text-red-700", @class_err]} :for={error <- @messages}><%= error %></span>
    </label>
    """
  end

  def date(assigns) do
    ~H"""
    <label for={@name}><%= @label %></label>
    <input type="date" id={@name} name={@name}  required value={@date} class={[@class, "static"]}/>
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
          <%= live_patch "✖",
            to: @return_to,
            id: "close",
            class: "phx-modal-close",
            phx_click: hide_modal()
          %>
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
