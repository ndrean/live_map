defmodule LiveMap.DatePicker do
  import Ecto.Changeset
  alias LiveMap.DatePicker

  defstruct [:event_date]
  @types %{event_date: :date}

  def changeset(attrs \\ %{}) do
    {%DatePicker{}, @types}
    |> cast(attrs, Map.keys(@types))
    |> validate_required([:event_date])
  end
end
