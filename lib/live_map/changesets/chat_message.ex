defmodule LiveMap.ChatMessage do
  @moduledoc """
  Schemaless changeset for the chat message
  """
  import Ecto.Changeset
  alias LiveMap.{ChatMessage, ChatCache}

  defstruct [:message, :receiver_id, :user_id]
  @types %{message: :string, receiver_id: :integer, user_id: :integer}

  @doc """
  Changeset checks if the name exists in the DB
  """
  def changeset(%ChatMessage{} = message, params \\ %{}) do
    {message, @types}
    |> cast(params, Map.keys(@types))
    |> validate_required([:message, :receiver_id, :user_id])
    |> validate_length(:message, min: 1)
    |> validate_notnil()
    |> validate_different()
  end

  def validate_notnil(changeset) do
    msg = get_field(changeset, :message)

    case msg do
      nil -> add_error(changeset, :message, "Message is empty")
      _ -> changeset
    end
  end

  def validate_different(changeset) do
    r_id = get_field(changeset, :receiver_id)
    u_id = get_field(changeset, :user_id)

    case r_id == u_id && (r_id != nil or u_id != nil) do
      true -> add_error(changeset, :message, "Error")
      false -> changeset
    end
  end

  def save(params) do
    case changeset(%ChatMessage{}, params).valid? do
      true ->
        %{"user_id" => user_id, "receiver_id" => receiver_id, "message" => message} = params
        ChatCache.save_message(user_id, receiver_id, String.trim(message))
        :ok

      false ->
        :error
    end
  end
end
