defmodule LiveMapWeb.EventChannel do
  use LiveMapWeb, :channel

  @impl true
  def join("event", _payload, socket) do
    {:ok, socket}

    # if authorized?(payload) do
    #   {:ok, socket}
    # else
    #   {:error, %{reason: "unauthorized"}}
    # end
  end

  # def handle_info("ping", p, socket) do
  #   {:noreply, socket}
  # end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  # @impl true
  # def handle_out("new publication", payload, socket) do
  #   broadcast(socket, "new publication", payload)
  #   {:noreply, socket}
  # end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (event:lobby).
  # @impl true
  # def handle_in("new pub", payload, socket) do
  #   broadcast(socket, "new pub", payload)
  #   {:noreply, socket}
  # end

  # Add authorization logic here as required.
  # defp authorized?(_payload) do
  #   true
  # end
end
