defmodule LiveMap.GeoJSON do
  defstruct type: "Feature",
            geometry: %{type: "LineString", coordinates: []},
            properties: %{
              ad1: "",
              ad2: "",
              date: Date.utc_today(),
              user: nil,
              distance: 0,
              status: nil
            }
end

defmodule LiveMap.GeoUtils do
  defp set_coords(%LiveMap.GeoJSON{} = geojson, startpoint, endpoint) do
    put_in(geojson.geometry.coordinates, [startpoint, endpoint])
  end

  defp set_props(%LiveMap.GeoJSON{} = geojson, ad1, ad2, date, user, distance) do
    put_in(geojson.properties, %{
      ad1: ad1,
      ad2: ad2,
      date: date,
      distance: distance,
      user: user
    })

    # |> dbg()
  end

  def new_from(
        geojson = %LiveMap.GeoJSON{},
        startpoint,
        endpoint,
        ad1,
        ad2,
        date,
        user,
        distance
      ) do
    geojson
    |> set_coords(startpoint, endpoint)
    |> set_props(ad1, ad2, date, user, distance)
  end
end
