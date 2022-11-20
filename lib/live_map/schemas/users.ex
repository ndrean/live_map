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

  @doc """
  Validations for User.
  """
  def changeset(user, attrs) do
    user
    |> Ecto.Changeset.cast(attrs, [:email])
    |> cast_assoc(:events)
    |> cast_assoc(:event_participants)
    |> validate_required([:email])
    |> unique_constraint(:email)
  end

  @doc """
  Creates a new user
  """
  def new(email) do
    User.changeset(%User{}, %{email: email})
    |> Repo.insert!(
      # returning: [:id], # or true
      on_conflict: [set: [updated_at: DateTime.utc_now()]],
      # {:replace_all_except, [:id, :email, :inserted_at]},
      conflict_target: :email
    )
  end

  @doc """
  Takes a key (eg :email, :id) and opts (eg [id: 1] or [email: "toto@com"]) and returns the value
  of the result map for this key

  ## Example

      iex> LiveMap.User.get_by!(:id, email: "toto@com")
      iex> LiveMap.User.get_by!(:email, %{id: 1})
  """
  def get_by!(key, opts) do
    Repo.get_by!(User, opts) |> Map.get(key)
  end

  def exists(email) do
    Repo.get_by(User, email: email) != nil
  end

  @doc """
  Returns the list of all users

  ## Example

      iex> LiveMap.User.list()
  """
  def list do
    Repo.all(User)
  end

  @doc """
  Returns the number of users

  ## Example

      iex> LiveMap.User.count()
  """
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
