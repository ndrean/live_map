defmodule LiveMap.NewEvent do
  @moduledoc """
  Schemaless changeset for the date
  """
  import Ecto.Changeset
  alias LiveMap.NewEvent

  defstruct [:event_date]
  @types %{event_date: :date}

  def changeset(%NewEvent{} = event_date, attrs \\ %{}) do
    {event_date, @types}
    |> Ecto.Changeset.cast(attrs, Map.keys(@types))
    |> Ecto.Changeset.validate_required([:event_date])
    |> validate_future()
  end

  defp validate_future(%{changes: %{event_date: event_date}} = changeset) do
    case Date.compare(event_date, Date.utc_today()) do
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
