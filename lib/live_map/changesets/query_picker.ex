defmodule LiveMap.QueryPicker do
  import Ecto.Changeset
  alias LiveMap.QueryPicker

  defstruct [:start_date, :end_date, :user, :distance, :status, :lat, :lng, :select]

  @types %{
    start_date: :date,
    end_date: :date,
    user: :string,
    distance: :float,
    status: :string,
    lat: :float,
    lng: :float,
    select: :string
  }

  def changeset(%QueryPicker{} = query, attrs \\ %{}) do
    {query, @types}
    |> cast(attrs, Map.keys(@types))
    |> validate_required([:start_date, :end_date])
    |> validate_future()
    |> validate_min()
  end

  def validate_min(%{changes: %{start_date: start_date}} = changeset) do
    yesterday = Date.utc_today() |> Date.add(-1)

    if Date.compare(start_date, yesterday) == :gt,
      do: changeset,
      else: add_error(changeset, :start_date, "Future dates only!")
  end

  def validate_min(changeset), do: changeset

  defp validate_future(%{changes: %{start_date: start_date, end_date: end_date}} = changeset) do
    case Date.compare(end_date, start_date) do
      :lt ->
        add_error(changeset, :end_date, "Future dates only!")

      _ ->
        changeset
    end
  end

  defp validate_future(changeset) do
    changeset
  end
end
