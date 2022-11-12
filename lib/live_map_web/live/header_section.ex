defmodule LiveMapWeb.HeaderSection do
  use Phoenix.Component
  import LiveMapWeb.LiveHelpers

  attr(:presence, :integer, default: 1)

  def display(assigns) do
    ~H"""
    <section class="flex mb-4 mt-4 justify-center">
      <div class="w-1/2 mt-0 flex flex-wrap items-center justify-center" id="geolocation">
        <button class="btn gap-2 font-['Roboto']">
          GPS
          <div class="badge">
            <.gps_svg/>
          </div>
        </button>
      </div>
      <div class="w-1/2 mt-0 flex justify-center items-center" id="chat">
        <button class="btn gap-2 font-['Roboto']">
          <.chat_svg/>
          <div class="badge badge-secondary font-['Roboto']"><%= @presence %></div>
        </button>
      </div>
    </section>
    """
  end
end
