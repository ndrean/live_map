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
    belongs_to :user, User
    has_many :event_participants, EventParticipants, on_delete: :delete_all
  end

  def changeset(%Event{} = event, attrs) do
    event
    |> cast(attrs, [:ad1, :ad2, :coordinates, :date, :user_id, :distance])
    |> validate_required([:coordinates])
    |> foreign_key_constraint(:user_id)
  end

  def new(params) do
    %Event{}
    |> changeset(params)
    |> Repo.insert()
  end

  def list() do
    Repo.all(Event)
  end
end
