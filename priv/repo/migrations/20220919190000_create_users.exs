defmodule LiveMap.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    # create table(:users, primary_key: false) do
    create table(:users) do
      # add :id, :uuid, primary_key: true
      add :email, :string, null: false
      # add :name, :string

      timestamps()
    end

    create unique_index(:users, [:email])
  end
end
