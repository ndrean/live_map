defmodule LiveMap.ChatSelect do
  @moduledoc """
  Schemaless changeset for the date
  """
  import Ecto.Changeset
  alias LiveMap.ChatSelect

  defstruct [:email]
  @types %{email: :string}

  @doc """
  Changeset checks if the name exists in the DB
  """
  def changeset(%ChatSelect{} = email, params \\ %{}) do
    {email, @types}
    |> cast(params, Map.keys(@types))
    |> validate_required([:email])
    |> validate_exists()
  end

  def validate_exists(changeset) do
    email = get_field(changeset, :email)

    if is_nil(email) do
      add_error(changeset, :email, "Not registered")
    else
      case LiveMap.User.get_by!(:id, email: email) do
        nil ->
          add_error(changeset, :name, "Not a registered user!")

        _ ->
          changeset
      end
    end
  end
end
