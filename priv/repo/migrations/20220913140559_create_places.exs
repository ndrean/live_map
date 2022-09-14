defmodule LiveMap.Repo.Migrations.CreatePlaces do
  use Ecto.Migration

  def change do
    create table(:places) do
      add :latitude, :float
      add :longitude, :float
      add :address, :string
      add :country, :string

      timestamps()
    end
  end
end
