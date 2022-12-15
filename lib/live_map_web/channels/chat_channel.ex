# defmodule LiveMapWeb.ChatChannel do
#   use LiveMapWeb, :channel

#   @impl true
#   def join(
#         "chat:lobby",
#         %{"token" => _token} = _payload,
#         %{assigns: %{current_id: current_id}} = socket
#       ) do
#     send(self(), :after_join)
#     {:ok, assign(socket, :current_id, current_id)}

#     # if authorized?(payload) do
#     #   {:ok, socket}
#     # else
#     #   {:error, %{reason: "unauthorized"}}
#     # end
#   end

#   def join("chat:" <> room_id, _params, socket) do
#     list_ids = String.split(room_id, "-")

#     send(self(), {:after_join_private, list_ids})
#     {:ok, socket}
#   end

#   def handle_info({:after_join_private, payload}, socket) do
#     broadcast!(socket, "shout", %{payload: "#{payload}"})
#     {:noreply, assign(socket, :room, "#{payload}")}
#   end

#   @impl true
#   def handle_info(:after_join, socket) do
#     broadcast!(socket, "shout", %{payload: "not yet"})
#     {:noreply, socket}
#   end

#   # def handle_info("ping", p, socket) do
#   #   {:noreply, socket}
#   # end

#   # Channels can be used in a request/response fashion
#   # by sending replies to requests from the client
#   # @impl true
#   # def handle_out("new publication", payload, socket) do
#   #   broadcast(socket, "new publication", payload)
#   #   {:noreply, socket}
#   # end

#   # It is also common to receive messages from the client and
#   # broadcast to everyone in the current topic (event:lobby).
#   # @impl true
#   # def handle_in("new pub", payload, socket) do
#   #   broadcast(socket, "new pub", payload)
#   #   {:noreply, socket}
#   # end

#   # Add authorization logic here as required.
#   # defp authorized?(_payload) do
#   #   true
#   # end
# end
