defmodule LiveMap.Repo do
  use Ecto.Repo,
    otp_app: :live_map,
    adapter: Ecto.Adapters.Postgres

  # import Geo.PostGIS
  import Ecto.Query
  alias LiveMap.{Repo, Event, EventParticipants, User}
  require Logger

  def min_distance(lng, lat) do
    case Repo.query(
           "SELECT MIN(ST_Distance(ST_MakePoint($1, $2), coordinates)) FROM events;",
           [lng, lat],
           log: true
         ) do
      {:ok, res} ->
        res.rows

      {:error, %Postgrex.Error{postgres: %{message: message}}} ->
        Logger.debug(message)
    end
  end

  # SELECT ROUND(
  #       CAST(ST_Distance(
  #           'SRID=4326;POINT(" <> coords <> ")'::geography,
  #           'SRID=4326;LINESTRING(0 45, 0 85)'::geography
  #           )
  #           AS numeric),
  # 0) from events;

  def default_date, do: Date.utc_today() |> Date.add(30)

  def events_in_map(lng, lat, distance, date \\ default_date()) do
    query = [
      "SELECT events.id, user_id, users.email, ad1,ad2,  date, coordinates, coordinates  <-> ST_MakePoint($1,$2) AS sphere_graphy
      FROM events
      INNER JOIN users ON user_id = users.id
      WHERE date < $4::date
      AND
      ST_Distance(ST_MakePoint($1,$2),coordinates)  < $3;"
    ]

    # case Ecto.Adapters.SQL.query!(Repo, query, [lng, lat, date, distance]) do
    case Repo.query(query, [lng, lat, distance, date], log: true) do
      {:ok, %Postgrex.Result{columns: columns, rows: rows}} ->
        Enum.map(rows, fn row -> Repo.load(Event, {columns, row}) end)

      {:error, %Postgrex.Error{postgres: %{message: message}}} ->
        Logger.debug(message)
    end
  end

  # :timer.tc(fn -> LiveMap.Repo.within(...). Is "events_in_map" faster with the index??
  def events_within(lng, lat, distance, date \\ default_date()) do
    query = [
      "SELECT events.id, user_id, users.email, ad1,ad2,  date, coordinates
      FROM events
      INNER JOIN users ON user_id = users.id
      WHERE ST_DWithin(ST_MakePoint($1,$2),coordinates, $3)
      AND date < $4::date;
      "
    ]

    case Repo.query(query, [lng, lat, distance, date], log: true) do
      {:ok, %Postgrex.Result{columns: columns, rows: rows}} ->
        Enum.map(rows, fn row -> Repo.load(Event, {columns, row}) end)

      {:error, %Postgrex.Error{postgres: %{message: message}}} ->
        Logger.debug(message)
    end
  end

  def features_in_map(lng, lat, distance, date \\ default_date()) do
    query = [
      "SELECT json_build_object(
      'type', 'FeatureCollection',
      'features', json_agg(ST_AsGeoJSON(t.*)::json)
      )
      FROM (
      SELECT users.email, events.ad1, events.ad2, events.date, events.coordinates,
      coordinates  <-> ST_MakePoint($1,$2) AS sphere_dist
      FROM events
      INNER JOIN users on events.user_id = users.id
      WHERE ST_Distance(ST_MakePoint($1, $2),coordinates)  < $3
      AND date < $4
      )
      AS t(email, ad1, ad2, date, coordinates);
      "
    ]

    case Repo.query(query, [lng, lat, distance, date]) do
      {:ok, %Postgrex.Result{rows: rows}} ->
        rows

      {:error, %Postgrex.Error{postgres: %{message: message}}} ->
        Logger.debug(message)
    end
  end

  def get_status(event_id) do
    Repo.query(
      "SELECT users.email, status, ep.user_id  FROM event_participants AS ep
      INNER JOIN users on users.id = ep.user_id
      WHERE ep.event_id = $1;
      ",
      [event_id]
    )
  end

  def list_participants_status_by_evt_id(e_id) do
    from(ep in "event_participants",
      join: u in "users",
      on: u.id == ep.user_id,
      where: ep.event_id == ^e_id,
      select: %{status: ep.status, user: u.email}
    )
    |> Repo.all()
  end

  def list_participants_by_evt_id_owner_email(e_id, owner_email) do
    from(ep in "event_participants",
      join: e in "events",
      on: ep.event_id == e.id,
      join: u in "users",
      on: u.id == e.user_id,
      join: up in "users",
      on: up.id == ep.user_id,
      where: u.email == ^owner_email and ep.event_id == ^e_id,
      select: %{status: ep.status, participant: up.email}
    )
    |> Repo.all()
  end

  def list_events_by_user_email(user_email) do
    from(ep in "event_participants",
      join: u in "users",
      on: u.id == ep.user_id,
      where: u.email == ^user_email,
      select: %{event_id: ep.event_id, status: ep.status, user: u.email, token: ep.ptoken}
    )
    |> Repo.all()
  end

  def token_email_by_evt_id_user_id(evt_id, u_id) do
    from(ep in "event_participants",
      join: e in "events",
      on: e.id == ep.event_id,
      join: u in "users",
      on: u.id == ep.user_id,
      where: ep.user_id == ^u_id and ep.event_id == ^evt_id,
      select: %{token: ep.ptoken, user: u.email}
    )
    |> Repo.one()
  end

  def owner_user_token_by_evt_id_user_id(event_id, user_id) do
    from(ep in "event_participants",
      join: e in "events",
      on: e.id == ep.event_id,
      join: owner in "users",
      on: owner.id == e.user_id,
      join: u in "users",
      on: u.id == ep.user_id,
      where: ep.user_id == ^user_id and ep.event_id == ^event_id,
      select: %{owner: owner.email, user: u.email, status: ep.status, token: ep.ptoken}
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
      select: %{token: ep.ptoken, status: ep.status, user: ^user_email, owner: owner.email}
    )
    |> Repo.one()
  end

  def raw(lng, lat, date, distance) do
    point = "#{lng} #{lat}"
    makepoint = "#{lng},#{lat}"

    Ecto.Adapters.SQL.query!(
      LiveMap.Repo,
      "SELECT events.id, user_id, users.email, ad1, ad2, date, coordinates  <-> ST_MakePoint(" <>
        makepoint <>
        ")
      AS sphere_graphy
      FROM events
      INNER JOIN users ON user_id = users.id
      WHERE date < '" <>
        date <>
        "' AND
      ST_Distance('SRID=4326;POINT(" <>
        point <> ")'::geography,coordinates)  < " <> Integer.to_string(distance) <> ";
      ",
      []
    )
  end
end
