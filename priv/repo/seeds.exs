# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#

alias LiveMap.{User, Repo, Event, EventParticipants}
# import Geo.PostGIS

%User{} |> User.changeset(%{email: "toto@mail.com"}) |> Repo.insert()
%User{} |> User.changeset(%{email: "bibi@mail.com"}) |> Repo.insert()
Repo.insert!(%User{email: "mama@mail.com"})

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

Repo.insert!(%Event{
  owner_id: Repo.get_by(User, email: "toto@mail.com").id,
  coordinates: %Geo.LineString{coordinates: [{0.0, 40.0}, {0.0, 41.0}], srid: 4326},
  ad1: "1 ad1",
  ad2: "1 ad2",
  date: ~D[2021-10-01]
})

Repo.insert!(%Event{
  owner_id: Repo.get_by(User, email: "bibi@mail.com").id,
  coordinates: %Geo.LineString{coordinates: [{0.0, 41.0}, {-1.0, 41.0}], srid: 4326},
  ad1: "1 ad1",
  ad2: "1 ad2",
  date: ~D[2021-10-01]
})

Repo.insert!(%Event{
  owner_id: Repo.get_by(User, email: "mama@mail.com").id,
  coordinates: %Geo.LineString{coordinates: [{-1.0, 41.0}, {-1.0, 40.0}], srid: 4326},
  ad1: "2 ad1",
  ad2: "2 ad2",
  date: ~D[2021-11-01]
})

Repo.insert!(%Event{
  owner_id: Repo.get_by(User, email: "mama@mail.com").id,
  coordinates: %Geo.LineString{coordinates: [{-1.0, 40.0}, {-1.0, 39.0}], srid: 4326},
  ad1: "3 ad1",
  ad2: "3 ad2",
  date: ~D[2021-12-01]
})

Repo.insert!(%Event{
  owner_id: Repo.get_by(User, email: "bibi@mail.com").id,
  coordinates: %Geo.LineString{coordinates: [{-1.0, 39.0}, {0.0, 39.0}], srid: 4326},
  ad1: "1 ad1",
  ad2: "1 ad2",
  date: ~D[2022-01-01]
})

Repo.insert!(%Event{
  owner_id: Repo.get_by(User, email: "toto@mail.com").id,
  coordinates: %Geo.LineString{coordinates: [{0.0, 39.0}, {0.0, 40.0}], srid: 4326},
  ad1: "1 ad1",
  ad2: "1 ad2",
  date: ~D[2022-02-01]
})

############################

LiveMap.Repo.insert!(%EventParticipants{
  user_id: Repo.get_by(User, email: "toto@mail.com").id,
  event_id: 1,
  ptoken: nil,
  status: :owner
})

LiveMap.Repo.insert!(%EventParticipants{
  user_id: Repo.get_by(User, email: "bibi@mail.com").id,
  event_id: 1,
  ptoken: nil,
  status: :pending
})

LiveMap.Repo.insert!(%EventParticipants{
  user_id: Repo.get_by(User, email: "mama@mail.com").id,
  event_id: 1,
  ptoken: nil,
  status: :pending
})

LiveMap.Repo.insert!(%EventParticipants{
  user_id: Repo.get_by(User, email: "bibi@mail.com").id,
  event_id: 2,
  ptoken: nil,
  status: :owner
})

LiveMap.Repo.insert!(%EventParticipants{
  user_id: Repo.get_by(User, email: "toto@mail.com").id,
  event_id: 2,
  ptoken: nil,
  status: :confirmed
})

LiveMap.Repo.insert!(%EventParticipants{
  user_id: Repo.get_by(User, email: "mama@mail.com").id,
  event_id: 2,
  ptoken: nil,
  status: :pending
})

LiveMap.Repo.insert!(%EventParticipants{
  user_id: Repo.get_by(User, email: "mama@mail.com").id,
  event_id: 3,
  ptoken: nil,
  status: :owner
})

LiveMap.Repo.insert!(%EventParticipants{
  user_id: Repo.get_by(User, email: "toto@mail.com").id,
  event_id: 3,
  ptoken: nil,
  status: :pending
})

LiveMap.Repo.insert!(%EventParticipants{
  user_id: Repo.get_by(User, email: "mama@mail.com").id,
  event_id: 4,
  ptoken: nil,
  status: :owner
})

LiveMap.Repo.insert!(%EventParticipants{
  user_id: Repo.get_by(User, email: "bibi@mail.com").id,
  event_id: 5,
  ptoken: nil,
  status: :owner
})

LiveMap.Repo.insert!(%EventParticipants{
  user_id: Repo.get_by(User, email: "toto@mail.com").id,
  event_id: 6,
  ptoken: nil,
  status: :owner
})

LiveMap.Repo.insert!(%EventParticipants{
  user_id: Repo.get_by(User, email: "bibi@mail.com").id,
  event_id: 6,
  ptoken: nil,
  status: :pending
})
