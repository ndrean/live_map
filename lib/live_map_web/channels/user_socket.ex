defmodule LiveMapWeb.UserSocket do
  use Phoenix.Socket
  require Logger

  @moduledoc """
  A Socket handler. Socket params are passed from the client and can be used to verify and authenticate a user. After
  verification, you can put default assigns into the socket that will be set for all channels, ie
  `{:ok, assign(socket, :user_id, verified_user_id)}`.
  To deny connection, return `:error`.
  """

  #
  #
  # It's possible to control the websocket connection and assign values that can be accessed by your channel topics.

  ## Channels

  channel "event", LiveMapWeb.EventChannel

  @doc """
  In "user_socket.js", it is set { params: {token: userToken}}  via DOM reading. The `userToken`
  is a computed value from the `user.id`. This params is added to the WS URI query string.
  When we pass it in the channel socket, this gives us a user identification in every channels.
  For example, the "event_channel" has now "curr_id" in the socket.
  """
  @impl true
  def connect(%{"token" => token} = _params, socket, _connect_info) do
    case LiveMap.Token.user_check(token) do
      {:error, reason} ->
        Logger.error("#{reason}: invalid token")
        {:error, reason}

      {:ok, user_id} ->
        Logger.warning("connected")
        {:ok, assign(socket, curr_id: user_id)}
    end
  end

  @doc """
  Socket id's are topics that allow you to identify all sockets for a given user:
  `def id(socket), do: "user_socket:{socket.assigns.user_id}"`
  would allow you to broadcast a "disconnect" event and terminate all active sockets and channels for a given user:
  `Elixir.LiveMapWeb.Endpoint.broadcast("user_socket:{user.id}", "disconnect", %{})`
  Returning `nil` makes this socket anonymous.
  """
  @impl true
  def id(_socket), do: nil
end
