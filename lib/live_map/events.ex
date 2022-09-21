defmodule LiveMap.Event do
  use Ecto.Schema
  import Ecto.Changeset
  alias LiveMap.{Repo, User, EventParticipants, Event}

  schema "events" do
    field :distance, :float, default: nil
    field :ad1, :string, default: nil
    field :ad2, :string, default: nil
    field :date, :date, default: Date.utc_today()
    field :coordinates, Geo.PostGIS.Geometry
    belongs_to :owner, User
    has_many :event_participants, EventParticipants
  end

  def changeset(%Event{} = event, attrs) do
    event
    |> cast(attrs, [:ad1, :ad2, :coordinates, :date, :owner_id])
    |> validate_required([:coordinates, :owner_id])
  end

  def create(params) do
    %Event{}
    |> changeset(params)
    |> Repo.insert()
  end
end
