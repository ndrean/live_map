defmodule LiveMap.DatePicker do
  #   defstruct [:event_date]
  #   @types %{event_date: :date}

  #   import Ecto.Changeset
  #   alias LiveMap.DatePicker

  #   def changeset(%DatePicker{} = event, attrs \\ %{}) do
  #     IO.inspect(Map.keys(@types))

  #     {event, @types}
  #     |> cast(attrs, Map.keys(@types))
  #     |> validate_required([:event_date])
  #   end

  #   # def set_date(%DatePicker{} = event_date, attrs \\ %{}) do
  #   #   DatePicker.changeset(event_date, attrs)
  #   # end
  # end

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
