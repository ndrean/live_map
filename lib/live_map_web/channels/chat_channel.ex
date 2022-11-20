defmodule LiveMapWeb.ChatChannel do
  use LiveMapWeb, :channel

  @impl true
  def join(
        "chat:lobby",
        %{"token" => _token} = _payload,
        %{assigns: %{current_id: current_id}} = socket
      ) do
    send(self(), :after_join)
    {:ok, assign(socket, :current_id, current_id)}

    # if authorized?(payload) do
    #   {:ok, socket}
    # else
    #   {:error, %{reason: "unauthorized"}}
    # end
  end

  def join("chat:" <> room_id, %{"token" => token} = _params, socket) do
    l1 = String.split(token, "-")
    l2 = String.split(room_id, "-")

    case same_room?(l1, l2) do
      true ->
        send(self(), {:after_join_private, l1})
        {:ok, socket}

      false ->
        :error
    end

    {:ok, socket}
  end

  def handle_info({:after_join_private, payload}, socket) do
    broadcast!(socket, "shout", %{b: "#{payload}"})
    {:noreply, assign(socket, :room, "#{payload}")}
  end

  @impl true
  def handle_info(:after_join, socket) do
    broadcast!(socket, "shout", %{a: 1})
    {:noreply, socket}
  end

  def same_room?(l1, l2) when length(l1) == length(l2) do
    Enum.map(l2, fn e2 -> Enum.filter(l1, fn e1 -> e1 == e2 end) end)
    |> List.flatten() == l2
  end

  def same_room?(_, _), do: false

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
