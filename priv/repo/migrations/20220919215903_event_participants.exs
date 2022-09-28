defmodule LiveMap.Repo.Migrations.EventParticipants do
  use Ecto.Migration

  def change do
    create table(:event_participants) do
      add :user_id, references(:users)
      add :event_id, references(:events)
      add :status, :event_status, null: false
      add :mtoken, :string
      timestamps()
    end

    create unique_index(:event_participants, [:event_id, :user_id], name: :evt_usr)

    # execute("
    #   CREATE UNIQUE INDEX unique_owner ON event_participants (event_id, status) WHERE (status = 'owner')
    # ")

    create unique_index(:event_participants, [:event_id],
             where: "status = 'owner'",
             name: :unique_owner
           )
  end
end
