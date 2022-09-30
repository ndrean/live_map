defmodule LiveMap.DatePicker do
  @moduledoc """
  Schemaless changeset for the date
  """
  import Ecto.Changeset
  alias LiveMap.DatePicker

  defstruct [:event_date]
  @types %{event_date: :date}

  def changeset(%DatePicker{} = date, attrs \\ %{}) do
    {date, @types}
    |> cast(attrs, Map.keys(@types))
    |> validate_required([:event_date])
    |> validate_future()
  end

  defp validate_future(%{changes: %{event_date: date}} = changeset) do
    case Date.compare(date, Date.utc_today()) do
      :lt ->
        add_error(changeset, :event_date, "Future dates only!")

      _ ->
        changeset
    end
  end

  defp validate_future(changeset) do
    changeset
  end
end
