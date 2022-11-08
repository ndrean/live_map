defmodule LiveMapWeb.HeaderSection do
  use Phoenix.Component

  attr(:presence, :integer, default: 1)

  def display(assigns) do
    IO.inspect(assigns.presence, label: "display")

    ~H"""
    <section class="flex mb-4 mt-4 justify-center">
      <div class="w-1/2 mt-0 flex flex-wrap items-center justify-center" id="geolocation">
        <div class="tooltip tooltip-right" data-tip="Geolocation">
          <button class="btn gap-2 font-['Roboto']">
            GPS
            <div class="badge">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-8 h-8">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z" />
                <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z" />
              </svg>
            </div>
          </button>
        </div>
      </div>
      <div class="w-1/2 mt-0 flex justify-center items-center" id="chat">
        <div class="tooltip tooltip-left" data-tip="Chat w/users">
          <button class="btn gap-2">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-12 h-12 p-1">
              <path stroke-linecap="round" stroke-linejoin="round" d="M8.625 12a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0H8.25m4.125 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0H12m4.125 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0h-.375M21 12c0 4.556-4.03 8.25-9 8.25a9.764 9.764 0 01-2.555-.337A5.972 5.972 0 015.41 20.97a5.969 5.969 0 01-.474-.065 4.48 4.48 0 00.978-2.025c.09-.457-.133-.901-.467-1.226C3.93 16.178 3 14.189 3 12c0-4.556 4.03-8.25 9-8.25s9 3.694 9 8.25z" />
            </svg>
            <div class="badge badge-secondary font-['Roboto']"><%= @presence %></div>
          </button>
        </div>
      </div>
    </section>
    """
  end
end
