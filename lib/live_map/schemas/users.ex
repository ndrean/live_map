defmodule LiveMap.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias LiveMap.{Repo, User, Event, EventParticipants}

  schema "users" do
    field :email, :string
    has_many(:events, Event)
    has_many(:event_participants, EventParticipants)
    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> Ecto.Changeset.cast(attrs, [:email])
    |> cast_assoc(:events)
    |> cast_assoc(:event_participants)
    |> validate_required([:email])
    |> unique_constraint(:email)
  end

  def new(email) do
    User.changeset(%User{}, %{email: email})
    |> Repo.insert!(
      # returning: [:id], # or true
      on_conflict: [set: [updated_at: DateTime.utc_now()]],
      # {:replace_all_except, [:id, :email, :inserted_at]},
      conflict_target: :email
    )
  end

  def email(id) do
    Repo.get_by(User, id: id).email
  end

  def from(email) do
    Repo.get_by(User, email: email)
  end

  def list do
    Repo.all(User)
  end

  def count do
    Repo.aggregate(User, :count, :id)
  end

  def search(string) do
    like = "%#{string}%"

    from(u in User,
      where: ilike(u.email, ^like)
    )
    |> Repo.all()
  end
end
