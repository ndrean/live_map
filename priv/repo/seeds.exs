# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#

alias LiveMap.{User, Repo, Event, EventParticipants}
User.new("toto@mail.com")
User.new("bibi@mail.com")
User.new("mama@mail.com")

Event.new(%{
  user_id: Repo.get_by(User, email: "toto@mail.com").id,
  coordinates: %Geo.LineString{coordinates: [{0.0, 40.0}, {0.0, 41.0}], srid: 4326},
  ad1: "1 ad0",
  ad2: "1 ad1",
  date: ~D[2021-10-01]
})

Event.new(%{
  user_id: Repo.get_by(User, email: "bibi@mail.com").id,
  coordinates: %Geo.LineString{coordinates: [{0.0, 41.0}, {-1.0, 41.0}], srid: 4326},
  ad1: "2 ad1",
  ad2: "2 ad2",
  date: ~D[2021-10-01]
})

Event.new(%{
  user_id: Repo.get_by(User, email: "mama@mail.com").id,
  coordinates: %Geo.LineString{coordinates: [{-1.0, 41.0}, {-1.0, 40.0}], srid: 4326},
  ad1: "3 ad1",
  ad2: "3 ad2"
})

Event.new(%{
  user_id: Repo.get_by(User, email: "mama@mail.com").id,
  coordinates: %Geo.LineString{coordinates: [{-1.0, 40.0}, {-1.0, 39.0}], srid: 4326},
  ad1: "4 ad1",
  ad2: "4 ad2",
  date: ~D[2021-12-01]
})

Event.new(%{
  user_id: Repo.get_by(User, email: "bibi@mail.com").id,
  coordinates: %Geo.LineString{coordinates: [{-1.0, 39.0}, {0.0, 39.0}], srid: 4326},
  ad1: "5 ad1",
  ad2: "5 ad2",
  date: ~D[2022-01-01]
})

Event.new(%{
  user_id: Repo.get_by(User, email: "toto@mail.com").id,
  coordinates: %Geo.LineString{coordinates: [{0.0, 39.0}, {0.0, 40.0}], srid: 4326},
  ad1: "6 ad1",
  ad2: "6 ad2",
  date: ~D[2022-02-01]
})

############################

EventParticipants.new(%{
  user_id: Repo.get_by(User, email: "toto@mail.com").id,
  event_id: 1,
  ptoken: nil,
  status: :owner
})

EventParticipants.new(%{
  user_id: Repo.get_by(User, email: "bibi@mail.com").id,
  event_id: 1,
  ptoken: nil,
  status: :pending,
  ptoken: "345"
})

EventParticipants.new(%{
  user_id: Repo.get_by(User, email: "mama@mail.com").id,
  event_id: 1,
  ptoken: nil,
  status: :pending,
  ptoken: "XCV"
})

EventParticipants.new(%{
  user_id: Repo.get_by(User, email: "bibi@mail.com").id,
  event_id: 2,
  ptoken: nil,
  status: :owner
})

EventParticipants.new(%{
  user_id: Repo.get_by(User, email: "toto@mail.com").id,
  event_id: 2,
  ptoken: nil,
  status: :confirmed
})

EventParticipants.new(%{
  user_id: Repo.get_by(User, email: "mama@mail.com").id,
  event_id: 2,
  ptoken: nil,
  status: :pending,
  ptoken: "DFGDG"
})

EventParticipants.new(%{
  user_id: Repo.get_by(User, email: "mama@mail.com").id,
  event_id: 3,
  ptoken: nil,
  status: :owner
})

EventParticipants.new(%{
  user_id: Repo.get_by(User, email: "toto@mail.com").id,
  event_id: 3,
  ptoken: nil,
  status: :pending,
  ptoken: "SDF"
})

EventParticipants.new(%{
  user_id: Repo.get_by(User, email: "mama@mail.com").id,
  event_id: 4,
  ptoken: nil,
  status: :owner
})

EventParticipants.new(%{
  user_id: Repo.get_by(User, email: "bibi@mail.com").id,
  event_id: 5,
  ptoken: nil,
  status: :owner
})

EventParticipants.new(%{
  user_id: Repo.get_by(User, email: "toto@mail.com").id,
  event_id: 6,
  ptoken: nil,
  status: :owner
})

EventParticipants.new(%{
  user_id: Repo.get_by(User, email: "bibi@mail.com").id,
  event_id: 6,
  ptoken: nil,
  status: :pending,
  ptoken: "AZE"
})

# Ecto.Adapters.SQL.query!(
#   LiveMap.Repo,
#   "INSERT INTO events (owner, coordinates, ad1, ad2, date)
#     SELECT
#       2,
#       ST_GeomFromText('LINESTRING(0 41, -1 41)',4326),
#       '2 ad1',
#       '2 ad2',
#       '2021/11/01'
#     FROM users
#     ORDER BY id ASC LIMIT 1;",
#   []
# )
