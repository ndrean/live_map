defmodule LiveMap.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def up do
    create table(:events) do
      add :owner_id, references(:users)
      add :distance, :float
      # add :coordinates, :geography[]
      add :ad1, :text
      add :ad2, :text
      add :date, :date
      # timestamps()
    end

    create index(:events, [:owner_id])
    create unique_index(:events, [:owner_id, :id])

    execute("ALTER TABLE events ADD COLUMN coordinates geography(LINESTRING, 4326);")
    execute("CREATE INDEX  events_gix ON events USING GIST (coordinates);")
  end

  def down do
    drop table(:events)
  end
end
