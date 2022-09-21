defmodule LiveMap.Repo.Migrations.PostgisEnum do
  use Ecto.Migration

  def up do
    execute("CREATE EXTENSION IF NOT EXISTS postgis")
    create_enum = "CREATE TYPE event_status AS ENUM ('owner', 'pending', 'confirmed')"
    execute(create_enum)
  end

  def down do
    execute("DROP TYPE event_status")
    execute "DROP EXTENSION IF EXISTS postgis"
  end
end
