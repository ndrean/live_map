defmodule LiveMap.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def up do
    create table(:events) do
      add :user_id, references(:users)
      # add :user_id, references(:users, type: :uuid, null: false)
      add :distance, :float
      add :ad1, :text
      add :ad2, :text
      add :date, :date
      add :color, :string, default: "#000"

      timestamps()
    end

    create index(:events, [:user_id])

    # execute("SELECT AddGeometryColumn('events', 'coordinates', '4326', 'LINESTRING', 2)")
    execute("ALTER TABLE events ADD COLUMN coordinates geography(LINESTRING);")
    execute("CREATE INDEX  events_gix ON events USING GIST (coordinates);")
  end

  def down do
    drop table(:events)
  end
end
