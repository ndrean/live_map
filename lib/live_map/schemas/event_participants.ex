defmodule LiveMap.EventParticipants do
  use Ecto.Schema
  import Ecto.{Changeset, Query}

  alias LiveMap.{Repo, EventParticipants, User}

  schema "event_participants" do
    belongs_to :user, LiveMap.User
    belongs_to :event, LiveMap.Event
    field :mtoken, :string, default: nil
    field :status, Ecto.Enum, values: [:owner, :pending, :confirmed]
    timestamps()
  end

  def changeset(%__MODULE__{} = event_participants, attrs) do
    event_participants
    |> cast(attrs, [:user_id, :event_id, :mtoken, :status])
    |> validate_required([:status, :event_id])
    |> unique_constraint([:user_id, :event_id], name: :evt_usr)
    |> unique_constraint([:event_id], where: "status = 'owner'", name: :unique_owner)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:event_id)
  end

  def new(params) do
    %__MODULE__{}
    |> changeset(params)
    |> Repo.insert()
  end

  @doc """
    Creates a user to an event, sets the status to pending and saves the token
  ```
  iex>LiveMap.EventParticipants.set_pending(%{event_id: 6, user_id: 2})
  {:ok, %LiveMap.EventParticipants{ ...}}
  ```
  """
  def set_pending(%{user_id: _user_id, event_id: _event_id} = params) do
    mtoken = LiveMap.Token.mail_generate(params)

    params =
      params
      |> Map.put(:mtoken, mtoken)
      |> Map.put(:status, :pending)

    LiveMap.EventParticipants.new(params)

    mtoken
  end

  @doc """
  Sets the status of a user for an event to confirmed and removes the token
  """
  def set_confirmed(%{event_id: event_id, user_id: user_id} = params) do
    params =
      params
      |> Map.put(:mtoken, nil)
      |> Map.put(:status, :confirmed)

    Repo.get_by(__MODULE__, %{event_id: event_id, user_id: user_id})
    |> changeset(params)
    |> Repo.update()
  end

  def list do
    Repo.all(EventParticipants)
  end

  def count do
    Repo.aggregate(EventParticipants, :count, :id)
  end

  def fetch(event_id) do
    from(ep in EventParticipants,
      where: ep.event_id == ^event_id
    )
    |> Repo.all()
  end

  @doc """
  Returns the record for [event_id, user_id]
  """
  def lookup(event_id, user_id) do
    Repo.get_by(EventParticipants, %{event_id: event_id, user_id: user_id})
  end

  @doc """
  Get all the records for this event with email and status
  ```
  iex>LiveMap.EventParticipants.email_with_evt_id(1)
  [
    %{ep_status: "confirmed", user_email: "toto", user_id: 1},
    %{ep_status: "confirmed", user_email: "bibi", user_id: 2},
    %{ep_status: "owner", user_email: "nevendrean@yahoo.fr", user_id: 3}
  ]
  ```
  """
  def email_with_evt_id(event_id) do
    from(ep in "event_participants",
      join: u in "users",
      on: u.id == ep.user_id,
      where: ep.event_id == ^event_id,
      select: %{user_id: ep.user_id, user_email: u.email, ep_status: ep.status}
    )
    |> Repo.all()
  end

  @doc """
  List of users.email and status by event_participant_id
  ```
  iex>LiveMap.EventParticipants.list_participants_status_by_evt_id(1)
  [
  %{status: "owner", user: "dreanneven@gmail.com"},
  %{status: "pending", user: "nevendrean@yahoo.fr"},
  %{status: "confirmed", user: "toto"}
  ]
  ```
  """
  def list_participants_status_by_evt_id(evt_id) do
    from(ep in "event_participants",
      join: u in "users",
      on: u.id == ep.user_id,
      where: ep.event_id == ^evt_id,
      select: %{status: ep.status, user: u.email, id: ep.event_id}
    )
    |> Repo.all()
  end

  @doc """
  List of events to which "user.email" participates with his status
  ```
  iex>LiveMap.EventParticipants.list_events_by_user_email("dreanneven@gmail.com")
  [
  %{event_id: 1, status: "owner", token: nil, user: "dreanneven@gmail.com"},
  %{event_id: 2, status: "owner", token: nil, user: "dreanneven@gmail.com"},
  %{event_id: 3, status: "confirmed", token: nil, user: "dreanneven@gmail.com"},
  %{event_id: 6, status: "owner", token: nil, user: "dreanneven@gmail.com"},
  %{
    event_id: 4,
    status: "pending",
    token: "SFMyNTY.g2gDbQAAABR1c2VyX2lkPTEmZXZ0rZw-SDZWDL8Eylk",
    user: "dreanneven@gmail.com"
  }
  ]
  ```
  """
  def list_events_by_user_email(user_email) do
    from(ep in "event_participants",
      join: u in "users",
      on: u.id == ep.user_id,
      where: u.email == ^user_email,
      select: %{event_id: ep.event_id, status: ep.status, user: u.email}
    )
    |> Repo.all()
  end

  @doc """
  List of events owner by "user.email"
  """

  # def list_events_owned_by(user_email) do
  #   from(ep in "event_participants",
  #   where:
  #   select: {user_id, status, user_email}
  #   )
  # end

  def token_email_by_evt_id_user_id(evt_id, u_id) do
    from(ep in "event_participants",
      join: e in "events",
      on: e.id == ep.event_id,
      join: u in "users",
      on: u.id == ep.user_id,
      where: ep.user_id == ^u_id and ep.event_id == ^evt_id,
      select: %{token: ep.mtoken, user: u.email}
    )
    |> Repo.one()
  end

  @doc """
  Get the owner email and user email given [event_id, user_id]
  """
  def owner_user_by_evt_id_user_id(event_id, user_id) do
    from(ep in "event_participants",
      join: e in "events",
      on: e.id == ep.event_id,
      join: owner in "users",
      on: owner.id == e.user_id,
      join: u in "users",
      on: u.id == ep.user_id,
      where: ep.user_id == ^user_id and ep.event_id == ^event_id,
      select: %{owner: owner.email, user: u.email, date: e.date}
    )
    |> Repo.one()
  end

  def owner_user_token_by_evt_id_user_email(event_id, user_email) do
    u_id = Repo.get_by(User, email: user_email).id

    from(ep in "event_participants",
      join: e in "events",
      on: e.id == ep.event_id,
      join: owner in "users",
      on: owner.id == e.user_id,
      where: ep.event_id == ^event_id and ep.user_id == ^u_id,
      select: %{token: ep.mtoken, status: ep.status, user: ^user_email, owner: owner.email}
    )
    |> Repo.one()
  end
end
