defmodule LiveMap.GeoJSON do
  defstruct type: "Feature",
            geometry: %{type: "LineString", coordinates: []},
            properties: %{ad1: "", ad2: "", date: Date.utc_today(), user: nil, status: nil}
end

defmodule LiveMap.Utils do
  def set_coords(startpoint, endpoint)
      when is_list(startpoint) and is_list(endpoint) do
    %LiveMap.GeoJSON{geometry: %{coordinates: [startpoint, endpoint]}}
  end
end
