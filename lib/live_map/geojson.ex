defmodule LiveMap.GeoJSON do
  @moduledoc """
  Struct to parse table "events" into GeoJSON format
  """

  # alias LiveMap.GeoJSON

  @derive {Jason.Encoder, except: []}
  defstruct type: "Feature",
            geometry: %{type: "LineString", coordinates: []},
            properties: %{
              id: nil,
              ad1: "",
              ad2: "",
              date: Date.utc_today(),
              email: nil,
              distance: 0,
              color: nil
            }

  # end

  # defmodule LiveMap.Utils do
  defp set_coords(%LiveMap.GeoJSON{} = geojson, startpoint, endpoint) do
    put_in(geojson.geometry.coordinates, [startpoint, endpoint])
  end

  defp set_props(%LiveMap.GeoJSON{} = geojson, id, ad1, ad2, date, user, distance, color) do
    put_in(geojson.properties, %{
      id: id,
      ad1: ad1,
      ad2: ad2,
      date: date,
      distance: distance,
      email: user,
      color: color
    })
  end

  def new_from(
        %LiveMap.GeoJSON{} = geojson,
        id,
        startpoint,
        endpoint,
        ad1,
        ad2,
        date,
        user,
        distance,
        color
      ) do
    geojson
    |> set_coords(startpoint, endpoint)
    |> set_props(id, ad1, ad2, date, user, distance, color)
  end
end
