defmodule LiveMap.NewEvent do
  @moduledoc """
  Schemaless changeset for the date
  """
  import Ecto.Changeset
  alias LiveMap.NewEvent

  defstruct [:date]
  @types %{date: :date}

  @doc """
  Changeset ensures that the date entered is a futur date
  """
  def changeset(%NewEvent{} = event, params \\ %{}) do
    {event, @types}
    |> cast(params, Map.keys(@types))
    |> validate_required([:date])
    |> validate_future()
  end

  defp validate_future(%{changes: %{date: date}} = changeset) do
    case Date.compare(date, Date.utc_today()) do
      :lt ->
        add_error(changeset, :date, "Future dates only!")

      _ ->
        changeset
    end
  end

  defp validate_future(changeset) do
    changeset
  end
end
