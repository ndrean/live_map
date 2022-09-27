defmodule LiveMap.EventParticipants do
  use Ecto.Schema
  import Ecto.Changeset
  alias LiveMap.{Repo, EventParticipants}

  schema "event_participants" do
    belongs_to :user, LiveMap.User
    belongs_to :event, LiveMap.Event
    field :ptoken, :string, default: nil
    field :status, Ecto.Enum, values: [:owner, :pending, :confirmed]
    timestamps()
  end

  def changeset(%__MODULE__{} = event_participants, attrs) do
    event_participants
    |> cast(attrs, [:user_id, :event_id, :ptoken, :status])
    |> validate_required([:status])
    |> unique_constraint([:user_id, :event_id], name: :evt_usr)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:event_id)
  end

  def new(params) do
    %__MODULE__{}
    |> changeset(params)
    |> Repo.insert()
  end

  def list do
    Repo.all(EventParticipants)
  end
end
