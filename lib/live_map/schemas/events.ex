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

  def new(params) do
    # to be refactored with Ecto.Multi
    {:ok, event} =
      %__MODULE__{}
      |> changeset(params)
      |> Repo.insert()

    EventParticipants.new(%{
      event_id: event.id,
      user_id: params.user_id,
      status: :owner
    })
  end

  def owner(id) do
    from(e in "events",
      join: u in "users",
      on: u.id == e.user_id,
      where: e.id == ^id,
      select: [u.email]
    )
    |> Repo.one()
  end

  def list() do
    Repo.all(Event)
  end

  def count do
    Repo.aggregate(Event, :count, :id)
  end

  def save_geojson(place, owner_id, date) do
    %{
      "coords" => [
        %{"lat" => lat1, "lng" => lng1, "name" => ad1},
        %{"lat" => lat2, "lng" => lng2, "name" => ad2}
      ],
      "distance" => distance,
      "color" => color
    } = place

    conv = fn s -> String.to_float(s) end

    case Event.new(%{
           user_id: owner_id,
           coordinates: %Geo.LineString{
             coordinates: [{conv.(lng2), conv.(lat2)}, {conv.(lng1), conv.(lat1)}],
             srid: 4326
           },
           distance: conv.(distance),
           ad1: ad1,
           ad2: ad2,
           date: date,
           color: color
         }) do
      {:ok, _} ->
        %GeoJSON{}
        |> GeoJSON.new_from(
          [conv.(lng2), conv.(lat2)],
          [conv.(lng1), conv.(lat1)],
          ad1,
          ad2,
          date,
          User.email(owner_id),
          conv.(distance),
          color
        )

      {:error, reason} ->
        {:error, reason}
    end
  end
end
