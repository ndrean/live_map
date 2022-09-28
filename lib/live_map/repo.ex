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
           [lng, lat],
           log: true
         ) do
      {:ok, res} ->
        res.rows |> List.flatten()

      {:error, %Postgrex.Error{postgres: %{message: message}}} ->
        Logger.debug(message)
    end
  end

  def default_date, do: Date.utc_today() |> Date.add(30)

  @doc """
  Fetch all the events centered at [lng,lat] with radius "distance" and time period, defaults to "today + 1 month".
  Return a GeoJSON features object.
  We passed a `%Geo.LineString{[x,y],[z,t]}` as the geometry, so it returns a "LINESTRING".
  ```
  iex> [GeoSJON features] = LiveMap.Repo.features_in_map(lng, lat, distance)
  """
  def features_in_map(lng, lat, distance, date \\ default_date()) do
    query = [
      "SELECT json_build_object(
      'type', 'FeatureCollection',
      'features', json_agg(ST_AsGeoJSON(t.*)::json)
      )
      FROM (
      SELECT users.email, events.ad1, events.ad2, events.date, events.color, events.coordinates, events.distance,
      coordinates  <-> ST_MakePoint($1,$2) AS sphere_dist
      FROM events
      INNER JOIN users on events.user_id = users.id
      WHERE ST_Distance(ST_MakePoint($1, $2),coordinates)  < $3
      AND date < $4
      )
      AS t(email, ad1, ad2, date, color, coordinates, distance);
      "
    ]

    case Repo.query(query, [lng, lat, distance, date]) do
      {:ok, %Postgrex.Result{rows: rows}} ->
        rows

      {:error, %Postgrex.Error{postgres: %{message: message}}} ->
        Logger.debug(message)
    end
  end

  def events_in_map(lng, lat, distance, date \\ default_date()) do
    query = [
      "SELECT events.id, user_id, users.email, ad1,ad2,  date, color, coordinates, coordinates  <-> ST_MakePoint($1,$2) AS sphere_graphy
      FROM events
      INNER JOIN users ON user_id = users.id
      WHERE date < $4::date
      AND
      ST_Distance(ST_MakePoint($1,$2),coordinates)  < $3;"
    ]

    case Repo.query(query, [lng, lat, distance, date], log: true) do
      {:ok, %Postgrex.Result{columns: columns, rows: rows}} ->
        Enum.map(rows, fn row -> Repo.load(Event, {columns, row}) end)

      {:error, %Postgrex.Error{postgres: %{message: message}}} ->
        Logger.debug(message)
    end
  end

  @doc """
  Version using ST_DWithin, less performant. Is "events_in_map" faster with the index??
  ```
  iex> :timer.tc(fn -> LiveMap.Repo.within(...).
  ```
  """
  def events_within(lng, lat, distance, date \\ default_date()) do
    query = [
      "SELECT events.id, user_id, users.email, ad1,ad2,  date, color, coordinates
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

  # def get_status(event_id) do
  #   Repo.query(
  #     "SELECT users.email, status, ep.user_id  FROM event_participants AS ep
  #     INNER JOIN users on users.id = ep.user_id
  #     WHERE ep.event_id = $1;
  #     ",
  #     [event_id]
  #   )
  # end
end
