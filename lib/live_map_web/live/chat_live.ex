defmodule LiveMapWeb.ChatLive do
  use LiveMapWeb, :live_component
  import LiveMapWeb.LiveHelpers
  alias LiveMap.{ChatMessage}
  alias LiveMapWeb.Endpoint

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col flex-auto h-full p-6">
      <div class="flex flex-col flex-auto flex-shrink-0 rounded-2xl bg-gray-100 h-full p-4 bg-black">
        <div class="flex flex-col h-full overflow-x-auto mb-4">
          <div class="flex flex-col h-full">
            <div class="grid grid-cols-12 gap-y-1"  :for={[emitter_id, _receiver_id, message] <- @messages}>

              <.left_message message={message} :if={to_string(emitter_id) == to_string(@user_id)}/>
              <.right_message message={message} :if={to_string(emitter_id) != to_string(@user_id)}}/>
            </div>
          </div>
        </div>
        <.form
          for={:f}
          phx-submit="send"
          phx-change="change"
          phx-target={@myself}
          id="form-chat"
        >
          <div class="flex flex-row items-center h-16 rounded-xl bg-white w-full px-1 bg-slate-900">
            <div class="flex-grow ml-4">
              <div class="relative w-full">
                <input type="hidden" value={@receiver_id} name="form-chat[receiver_id]"/>
                <input type="hidden" value={@user_id} name="form-chat[user_id]"/>

                <input
                  type="text" aria-label="new message"
                  name="form-chat[message]"
                  disabled={@receiver_id == nil}
                  autofocus={true}
                  class="flex w-full border rounded-xl focus:outline-none focus:border-indigo-300 pl-4 h-10"
                  value={@message}
                />
              </div>
            </div>
            <div class="ml-4">
              <button form="form-chat" class="flex items-center justify-center bg-indigo-500 hover:bg-indigo-600 rounded-xl text-white px-4 py-1 flex-shrink-0">
                <span>Send</span>
                <span class="ml-2">
                  <svg
                    class="w-4 h-4 transform rotate-45 -mt-px"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"
                    ></path>
                  </svg>
                </span>
              </button>
            </div>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("change", %{"form-chat" => params}, socket) do
    changeset =
      %ChatMessage{}
      |> ChatMessage.changeset(params)
      |> Map.put(:action, :validate)

    case changeset.valid? do
      false ->
        {:noreply, assign(socket, message: nil)}

      true ->
        update = assign(socket, changeset: changeset, message: params["message"])
        {:noreply, update}
    end
  end

  @impl true
  def handle_event("send", %{"form-chat" => %{"message" => ""}}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("send", %{"form-chat" => params}, socket) do
    case LiveMap.ChatMessage.save(params) do
      :error ->
        {:noreply, assign(socket, :message, "")}

      :ok ->
        body = String.trim(params["message"])
        :ok = notify_message(params["user_id"], params["receiver_id"], body)
        {:noreply, assign(socket, :message, "")}
    end
  end

  defp notify_message(emitter_id, receiver_id, message) do
    Endpoint.broadcast!("live_chat", "new_message", [emitter_id, receiver_id, message])
  end
end