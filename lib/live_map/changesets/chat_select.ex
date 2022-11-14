defmodule LiveMap.ChatSelect do
  @moduledoc """
  Schemaless changeset for the date
  """
  import Ecto.Changeset
  alias LiveMap.ChatSelect

  defstruct [:name]
  @types %{name: :string}

  @doc """
  Changeset checks if the name exists in the DB
  """
  def changeset(%ChatSelect{} = name, params \\ %{}) do
    {name, @types}
    |> cast(params, Map.keys(@types))
    |> validate_required([:name])
    |> validate_exists()
  end

  def validate_exists(%{changes: %{name: name}} = changeset) do
    case LiveMap.User.from(name) do
      nil ->
        add_error(changeset, :name, "Not a registered user!")

      _ ->
        changeset
    end
  end

  def validate_exists(changeset), do: changeset
end
