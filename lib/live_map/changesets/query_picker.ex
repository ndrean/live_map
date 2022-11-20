defmodule LiveMap.QueryPicker do
  import Ecto.Changeset
  alias LiveMap.QueryPicker

  # defstruct [:start_date, :end_date, :user, :distance, :status, :lat, :lng, :select]
  defstruct [:start_date, :end_date, :user, :status]

  @types %{
    start_date: :date,
    end_date: :date,
    user: :string,
    status: :string
  }

  @doc """
  Changeset ensures end-date > start-date
  """
  def changeset(%QueryPicker{} = query, attrs \\ %{}) do
    {query, @types}
    |> cast(attrs, Map.keys(@types))
    |> validate_required([:start_date, :end_date])
    |> validate_future()

    # |> validate_min()
  end

  def validate_min(changeset), do: changeset
  # def validate_min(%{changes: %{start_date: start_date}} = changeset) do
  #   yesterday = Date.utc_today() |> Date.add(-1)

  #   if Date.compare(start_date, yesterday) == :gt,
  #     do: changeset,
  #     else: add_error(changeset, :start_date, "Future dates only!")
  # end

  defp validate_future(changeset) do
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)

    if is_nil(start_date) and is_nil(end_date) do
      changeset
    else
      case Date.compare(end_date, start_date) do
        :lt ->
          add_error(changeset, :end_date, "Check dates")

        _ ->
          changeset
      end
    end
  end
end
