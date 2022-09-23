defmodule LiveMap.Repo.Migrations.EventParticipants do
  use Ecto.Migration

  def change do
    create table(:event_participants) do
      add :user_id, references(:users)
      add :event_id, references(:events)
      add :status, :event_status, null: false
      add :ptoken, :string
    end

    create unique_index(:event_participants, [:event_id, :user_id])
    # for queries  "WHERE ep.even_id= .. AND ep.user_id=..
  end
end
