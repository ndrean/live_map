defmodule LiveMap.EventParticipants do
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias LiveMap.{Repo, EventParticipants}

  schema "event_participants" do
    belongs_to :user, LiveMap.User
    # belongs_to :owner, LiveMap.User
    belongs_to :event, LiveMap.Event
    field :ptoken, :string, default: nil
    field :status, Ecto.Enum, values: [:owner, :pending, :confirmed]
  end

  def changeset(%EventParticipants{} = event_participants, attrs) do
    event_participants
    |> cast(attrs, [:user_id, :event_id, :ptoken, :status])
    |> validate_required([:status])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:event_id)
  end

  def new(params) do
    %EventParticipants{}
    |> changeset(params)
    |> Repo.insert()
  end

  def list do
    Repo.all(EventParticipants)
  end

  # def update(params) do
  #   %EventParticipants{}
  #   |> changeset(params)
  #   |> Ecto.Query.update_all()
  # end
end
