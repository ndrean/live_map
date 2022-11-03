defmodule LiveMap.Repo do
  use Ecto.Repo,
    otp_app: :live_map,
    adapter: Ecto.Adapters.Postgres

  # import Ecto.Query
  alias LiveMap.{Repo, Event}
  require Logger

  @doc """
  Returns the closest event to current location
  ```
  iex> [distance] = LiveMap.Repo.min_distance(lng, lat)
  """
  def min_distance(lng, lat) do
    case Repo.query(
           "SELECT
              ROUND(
                MIN(ST_Distance(ST_MakePoint($1, $2), coordinates))
              )
              FROM events;",
           [lng, lat]
         ) do
      {:ok, res} ->
        res.rows |> List.flatten()

      {:error, %Postgrex.Error{postgres: %{message: message}}} ->
        Logger.debug(message)
        {:error, message}
    end
  end

  def default_date(d), do: Date.utc_today() |> Date.add(d)

  @doc """
  Fetch all the events centered at [lng,lat] with radius "distance" and time period, defaults to "today + 1 month".
  Return a GeoJSON features object.
  We passed a `%Geo.LineString{[x,y],[z,t]}` as the geometry, so it returns a "LINESTRING".
  ```s
  iex> [GeoSJON features] = LiveMap.Repo.features_in_map(lng, lat, distance)
  """
  # events.coordinates, coordinates  <-> ST_MakePoint($1,$2) AS sphere_dist
  def features_in_map(
        lng,
        lat,
        distance,
        date_start \\ default_date(0),
        date_end \\ default_date(30)
      ) do
    query = [
      "SELECT json_build_object(
        'type', 'FeatureCollection',
        'features', json_agg(ST_AsGeoJSON(t.*)::json)
      )
      FROM (
        SELECT events.id, users.email, events.ad1, events.ad2, events.date, events.color, events.distance,
        events.coordinates, events.coordinates  <-> ST_MakePoint($1,$2, 4326) AS sphere_dist
        FROM events
        INNER JOIN users on events.user_id = users.id
        WHERE ST_DWithin(ST_MakePoint($1, $2, 4326),coordinates, $3)
        AND events.date >= $4::date AND events.date < $5::date
        ORDER BY sphere_dist
        ) AS t(id, email, ad1, ad2, date, color, coordinates, distance);
        "
    ]

    # FROM (
    #     SELECT events.id, users.email, events.ad1, events.ad2, events.date, events.color, events.distance,
    #     events.coordinates, events.coordinates  <-> ST_MakePoint($1,$2)::geometry AS sphere_dist
    #     FROM events
    #     INNER JOIN users on events.user_id = users.id
    #     WHERE ST_DWithin(ST_MakePoint($1, $2)::geometry,coordinates, $3)
    #     AND events.date >= $4::date AND events.date < $5::date
    #     ORDER BY sphere_dist
    #     ) AS t(id, email, ad1, ad2, date, color, coordinates, distance);
    #     "

    case Repo.query(query, [lng, lat, distance, date_start, date_end]) do
      {:ok, %Postgrex.Result{rows: rows}} ->
        {:ok, rows}

      {:error, %Postgrex.Error{postgres: %{message: message}}} ->
        Logger.warning(message)
        {:error, message}
    end
  end

  def select_in_map(%{
        lng: lng,
        lat: lat,
        distance: distance,
        start_date: start_date,
        end_date: end_date
      }) do
    query = [
      "WITH geo_events AS (
        SELECT events.id,  events.date, ep.user_id, u.email, ep.status,
        coordinates  <-> ST_MakePoint($1,$2) AS sphere_graphy
        FROM events
        JOIN event_participants ep ON ep.event_id = events.id
        JOIN users u ON u.id = ep.user_id
        WHERE date >= $4::date AND date <= $5::date
        AND
        ST_DWithin(ST_MakePoint($1,$2),events.coordinates, $3)
      ),
      status_agg AS (
        SELECT id, status, ARRAY_AGG(email) emails
        FROM geo_events
        GROUP BY id, status
      ),
      date_agg AS (
        SELECT id, date, email
        FROM geo_events
      ),
      unsorted AS (
      SELECT s.id, jsonb_object_agg(status, emails) status_email, jsonb_object_agg('date', date) date_date
      FROM status_agg s
      JOIN date_agg d ON d.id = s.id
      GROUP BY s.id
      )
      SELECT id, status_email, date_date
      FROM unsorted
      ORDER BY date_date
      ;"
    ]

    case Ecto.Adapters.SQL.query(
           Repo,
           query,
           [lng, lat, distance, start_date, end_date]
         ) do
      {:ok, %Postgrex.Result{columns: _columns, rows: rows}} ->
        rows

      {:error, %Postgrex.Error{postgres: %{message: message}}} ->
        Logger.debug(message)
        {:error, message}
    end
  end

  def selectbis_in_map(%{
        lng: lng,
        lat: lat,
        distance: distance,
        start_date: start_date,
        end_date: end_date
      }) do
    query = [
      "SELECT events.id, events.user_id, users.email, events.ad1, events.ad2,  events.date, events.color,
      ST_Transform(events.coordinates, 4326),  events.coordinates  <-> ST_MakePoint($1,$2)::geometry AS sphere_graphy
    FROM events
    INNER JOIN users ON events.user_id = users.id
    INNER JOIN event_participants AS ep on events.id = ep.event_id
    WHERE events.date >= $4::date AND events.date <= $5::date
    AND
    ST_Distance(ST_MakePoint($1,$2),events.coordinates)  < $3;
  "
    ]

    case Repo.query(query, [lng, lat, distance, start_date, end_date], log: true) do
      {:ok, %Postgrex.Result{columns: columns, rows: rows}} ->
        Enum.map(rows, fn row ->
          Repo.load(Event, {columns, row})
          |> Repo.preload(:event_participants)
        end)

      {:error, %Postgrex.Error{postgres: %{message: message}}} ->
        Logger.debug(message)
        {:error, message}
    end
  end
end
