defmodule LiveMap.GeoJSON do
  alias LiveMap.User

  @moduledoc """
  Struct to parse the "flat" table "events" into GeoJSON format.

  Exposes one function: `into_geojson` to convert the "flat" event object from the DB into a GeoJSON format object for the front-end to use.
  """

  alias LiveMap.GeoJSON

  @derive {Jason.Encoder, except: []}
  defstruct type: "Feature",
            geometry: %Geo.LineString{coordinates: []},
            properties: %{
              id: nil,
              ad1: "",
              ad2: "",
              date: "",
              email: nil,
              distance: 0,
              color: nil
            }

  defp set_coords(%GeoJSON{} = geojson, coordinates) do
    put_in(geojson.geometry.coordinates, coordinates)
  end

  defp swap_id_for_email(%GeoJSON{} = geojson, id) do
    geojson
    |> Map.put(:email, User.email(id))
    |> Map.delete(:user_id)
  end

  defp set_props(%GeoJSON{} = geojson, id, ad1, ad2, date, distance, color) do
    put_in(geojson.properties, %{
      id: id,
      ad1: ad1,
      ad2: ad2,
      date: date,
      distance: distance,
      color: color
    })
  end

  @doc """
  Converts the params into a %GeoJSON {} struct.
  """
  def into_geojson(live_map_event) do
    %{
      id: id,
      coordinates: %Geo.LineString{coordinates: coordinates},
      ad1: ad1,
      ad2: ad2,
      date: date,
      user_id: user_id,
      distance: distance,
      color: color
    } = live_map_event

    %GeoJSON{}
    |> set_coords(coordinates)
    |> swap_id_for_email(user_id)
    |> set_props(id, ad1, ad2, date, distance, color)
  end
end
