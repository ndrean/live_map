#  defined in its own file: see <https://github.com/elixir-ecto/postgrex#extensions>

Postgrex.Types.define(
  LiveMap.PostgresTypes,
  [Geo.PostGIS.Extension] ++ Ecto.Adapters.Postgres.extensions(),
  json: Jason
)
