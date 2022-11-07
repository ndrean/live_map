defmodule LiveMapWeb.LiveHelpers do
  use Phoenix.Component
  import Phoenix.LiveView.Helpers

  alias Phoenix.LiveView.JS

  @moduledoc """
  Function HTML components for LiveView
  """

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
  def date(assigns) do
    ~H"""
    <label for={@name}><%= @label %>
    <input type="date" id={@name} name={@name} required value={@date} class={@class} />
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
