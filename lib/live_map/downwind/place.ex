defmodule LiveMap.Downwind.Place do
  use Ecto.Schema
  import Ecto.Changeset

  schema "places" do
    field :address, :string
    field :country, :string
    field :latitude, :float
    field :longitude, :float

    timestamps()
  end

  @doc false
  def changeset(place, attrs) do
    place
    |> cast(attrs, [:latitude, :longitude, :address, :country])
    |> validate_required([:latitude, :longitude, :address, :country])
  end
end
