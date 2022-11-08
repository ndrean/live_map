defmodule LiveMap.Repo do
  use Ecto.Repo,
    otp_app: :live_map,
    adapter: Ecto.Adapters.Postgres

  # import Ecto.Query
  alias LiveMap.{Repo, Event}
  require Logger

  @moduledoc """
  Queries the PostGIS database
  """

  @doc """
  Test helper to Return the closest event to current location
  ```
  iex> [distance] = LiveMap.Repo.min_distance(lng, lat)
  """
  def min_distance(lng, lat) do
    case Repo.query(
           "SELECT
              ROUND(
                MIN(ST_Distance(ST_MakePoint($1, $2), events.coordinates))
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

  Returns a GeoJSON features object.

  We passed a `%Geo.LineString{[x,y],[z,t]}` with type GEOGRAPHY.

    ```
    iex> [GeoSJON features] = LiveMap.Repo.features_in_map(lng, lat, distance)
    ```
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
        SELECT
          e.id, users.email, e.ad1, e.ad2, e.date, e.color, e.distance, e.coordinates
          FROM events AS e
          INNER JOIN users on e.user_id = users.id
          WHERE ST_DWithin(ST_MakePoint($1,$2), e.coordinates, $3, false)
          AND e.date >= $4::date AND e.date < $5::date
      )
      AS t(id, email, ad1, ad2, date, color, distance, coordinates);
      "
    ]

    # WHERE e.coordinates  <-> ST_MakePoint($1,$2) < $3 .... ORDER BY e.date DESC

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
        end_date: end_date,
        status: ""
      }) do
    query = [
      "WITH geo_events AS (
        SELECT e.id,  e.date, ep.user_id, u.email, ep.status
        FROM events AS e
        JOIN event_participants ep ON ep.event_id = e.id
        JOIN users u ON u.id = ep.user_id
        WHERE date >= $4::date AND date <= $5::date
        AND ST_DWithin(ST_MakePoint($1,$2), e.coordinates, $3, false)
      ),
      status_agg AS (
        SELECT id, status, ARRAY_AGG(email) emails
        FROM geo_events
        GROUP BY id, status
      ),
      date_agg AS (
        SELECT id, date, email
        FROM geo_events
      )
      SELECT s.id, jsonb_object_agg(status, emails) status_email, jsonb_object_agg('date', date) date_date
      FROM status_agg s
      JOIN date_agg d ON d.id = s.id
      GROUP BY d.date, s.id
      ORDER BY d.date ASC;
      "
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

  def select_in_map(%{
        lng: lng,
        lat: lat,
        distance: distance,
        start_date: start_date,
        end_date: end_date,
        status: status
      }) do
    query = [
      "WITH geo_events AS (
        SELECT e.id,  e.date, ep.user_id, u.email, ep.status
        FROM events AS e
        JOIN event_participants ep ON ep.event_id = e.id
        JOIN users u ON u.id = ep.user_id
        WHERE date >= $4::date AND date <= $5::date
        AND ST_DWithin(ST_MakePoint($1,$2), e.coordinates, $3, false)
        AND  ep.status = $6
      ),
      status_agg AS (
        SELECT id, status, ARRAY_AGG(email) emails
        FROM geo_events
        GROUP BY id, status
      ),
      date_agg AS (
        SELECT id, date, email
        FROM geo_events
      )
      SELECT s.id, jsonb_object_agg(status, emails) status_email, jsonb_object_agg('date', date) date_date
      FROM status_agg s
      JOIN date_agg d ON d.id = s.id
      GROUP BY s.id;
     "
    ]

    case Ecto.Adapters.SQL.query(
           Repo,
           query,
           [lng, lat, distance, start_date, end_date, status]
         ) do
      {:ok, %Postgrex.Result{columns: _columns, rows: rows}} ->
        rows

      {:error, %Postgrex.Error{postgres: %{message: message}}} ->
        Logger.debug(message)
        {:error, message}
    end
  end

  # def selectbis_in_map(%{
  #       lng: lng,
  #       lat: lat,
  #       distance: distance,
  #       start_date: start_date,
  #       end_date: end_date
  #     }) do
  #   query = [
  #     "SELECT e.id, e.user_id, u.email, e.ad1, e.ad2,  e.date, e.color,
  #     events.coordinates
  #     FROM events AS e
  #     INNER JOIN users AS u ON e.user_id = u.id
  #     INNER JOIN event_participants AS ep on e.id = ep.event_id
  #     WHERE e.date >= $4::date AND e.date <= $5::date
  #     AND e.coordinates <-> ST_MakePoint($1, $2) < $3
  #     ORDER BY e.date DESC;
  #     "
  #   ]

  #   case Repo.query(query, [lng, lat, distance, start_date, end_date], log: true) do
  #     {:ok, %Postgrex.Result{columns: columns, rows: rows}} ->
  #       Enum.map(rows, fn row ->
  #         Repo.load(Event, {columns, row})
  #         |> Repo.preload(:event_participants)
  #       end)

  #     {:error, %Postgrex.Error{postgres: %{message: message}}} ->
  #       Logger.debug(message)
  #       {:error, message}
  #   end
  # end
end
