defmodule LiveMap.User do
  use Ecto.Schema
  import Ecto.Changeset
  # import Ecto.Query
  alias LiveMap.{Repo, User, Event, EventParticipants}

  schema "users" do
    field :email, :string
    field :name, :string
    has_many(:events, Event)
    has_many(:event_participants, EventParticipants)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email])
    |> validate_required([:email])
    |> unique_constraint(:email)
  end

  def new(email) do
    {:ok, user} =
      User.changeset(%User{}, %{email: email})
      |> Repo.insert(on_conflict: :nothing)

    user
  end

  def list do
    Repo.all(User)
  end
end

# {:replace, [:email]}, returning: true, conflict_target: :email)
