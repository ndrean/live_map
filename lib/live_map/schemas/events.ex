defmodule LiveMap.Event do
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias LiveMap.{Repo, User, EventParticipants, Event, GeoJSON}

  schema "events" do
    field :distance, :float, default: nil
    field :ad1, :string, default: nil
    field :ad2, :string, default: nil
    field :date, :date, default: Date.utc_today()
    field :coordinates, Geo.PostGIS.Geometry
    field :color, :string
    timestamps()
    belongs_to :user, User
    has_many :event_participants, EventParticipants, on_delete: :delete_all
  end

  def changeset(%Event{} = event, attrs) do
    event
    |> cast(attrs, [:ad1, :ad2, :coordinates, :date, :user_id, :distance, :color])
    |> cast_assoc(:event_participants)
    |> validate_required([:coordinates, :user_id, :date])
    |> foreign_key_constraint(:user_id)
  end

  @doc """
  A multi to create in one transaction (important for Rollback) a new event and a new event_participant with the previous EVENT_ID and with the user as the owner of the event
  """
  def new(params) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:evt, Event.changeset(%Event{}, params))
    |> Ecto.Multi.run(:ep, fn repo, %{evt: event} ->
      repo.insert(
        EventParticipants.changeset(%EventParticipants{}, %{
          event_id: event.id,
          user_id: params.user_id,
          status: :owner
        })
      )
    end)
    |> Repo.transaction()
  end

  @doc """
  Return a GeoJSON struct after saving an Event and owner associated EvetnParticipant
  """
  def save_geojson(place, owner_id, date) do
    %{
      "coords" => [
        %{"lat" => lat1, "lng" => lng1, "name" => ad1},
        %{"lat" => lat2, "lng" => lng2, "name" => ad2}
      ],
      "distance" => distance,
      "color" => color
    } = place

    check = fn s -> if is_binary(s), do: String.to_float(s), else: s / 1 end
    lat1 = check.(lat1)
    lat2 = check.(lat2)
    lng1 = check.(lng1)
    lng2 = check.(lng2)
    distance = check.(distance)

    case Event.new(%{
           user_id: owner_id,
           coordinates: %Geo.LineString{
             coordinates: [{lng2, lat2}, {lng1, lat1}],
             srid: 4326
           },
           distance: distance,
           ad1: ad1,
           ad2: ad2,
           date: date,
           color: color
         }) do
      {:error, _op, _reason, _others} ->
        :error

      {:ok, %{evt: %LiveMap.Event{id: event_id}}} ->
        GeoJSON.new_from(
          %GeoJSON{},
          event_id,
          [lng2, lat2],
          [lng1, lat1],
          ad1,
          ad2,
          date,
          User.email(owner_id),
          distance,
          color
        )
    end
  end

  @doc """
  List of all users
  """
  def list() do
    Repo.all(Event)
  end

  @doc """
  Number of users
  """
  def count do
    Repo.aggregate(Event, :count, :id)
  end

  @doc """
  Delete an event given its ID
  """
  def delete_event(id) do
    Repo.get_by(Event, id: id)
    |> Repo.delete()
  end

  @doc """
  Find the owner of an event given its ID
  """
  def owner(id) do
    from(e in "events",
      join: u in "users",
      on: u.id == e.user_id,
      where: e.id == ^id,
      select: [u.email]
    )
    |> Repo.one()
  end
end
