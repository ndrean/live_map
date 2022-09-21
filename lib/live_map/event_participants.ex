defmodule LiveMap.EventParticipants do
  use Ecto.Schema
  import Ecto.Changeset

  schema "event_participants" do
    belongs_to :user, LiveMap.User
    belongs_to :owner, LiveMap.User
    belongs_to :event, LiveMap.Event
    field :ptoken, :string, default: nil
    field :status, Ecto.Enum, values: [:owner, :pending, :confirmed]
  end

  def changeset(%LiveMap.EventParticipants{} = event_participants, attrs) do
    event_participants
    |> cast(attrs, [:user_id, :event_id, :ptoken, :status])
    |> validate_required([:status])
  end
end
