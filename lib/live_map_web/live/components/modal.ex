defmodule LiveMapWeb.Modal do
  use Phoenix.Component

  @moduledoc """
  This modal uses DaisyUI. Np `Phoenix.LiveView.JS`, just CSS.
  <https://v1.daisyui.com/components/modal/>
  """

  def display(assigns) do
    ~H"""
    <div class="modal-box text-white">
      <p>The <%= @date %>, a <%= @d %> km event:</p>
      <p class="divider"></p>
      <p class="close">
        <%= @ad1 %>
      </p>
      <p class="divider"></p>
      <p><%= @ad2 %></p>

      <p class="divider">List of participants:</p>
      <div class="overflow-y-auto overflow-hidden">
        <table class="table w-full">
          <thead class="bg-slate-500">
            <tr>
              <th>Owner</th>
              <th>Pending</th>
              <th>Confirmed</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <th class="text-xs"><%= @owner %></th>
              <td>
                <p
                  :for={user <- @pending}
                  class={[@pending != [] && "text-orange-700"]}
                  class="text-xs"
                >
                  <%= user %>
                </p>
              </td>
              <td>
                <p
                  :for={user <- @confirmed}
                  class={[@confirmed != [] && "text-lime-600"]}
                  class="text-xs"
                >
                  <%= user %>
                </p>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="modal-action">
        <label for={"my-modal-#{@mid}"} class="btn">Close</label>
      </div>
    </div>
    """
  end
end
