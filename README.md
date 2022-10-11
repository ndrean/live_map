# LiveMap

TODO: improve this or write a post in dev.to !!!


mix phx.gen.context Downwind Place places latitude:float longitude:float addre
ss:string country:string

mix phx.gen.context Downwind Event events start end date:date
cd assets && npm i leaflet leaft-control-geocder valtio

```elixir
config.esbuild
--target=es2020 #<- Valtio
--sourcemap #<- Leaflet
--loader:.png=dataurl #<- Leaflet icon
```

Leaflet -> id="map", style="height, width"
app.css
@import 'leaflet/dist/leaflet.css';
@import 'leaflet-control-geocoder/dist/Control.Geocoder.css';

router
live "/"

export GOOGLE_CLIENT_ID=427903880331-eo7ihmos753oat8qbblfomm121htqjnf.apps.googleusercontent.com
export GOOGLE_CLIENT_SECRET=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

export GITHUB_CLIENT_ID=2a152f5479f2ef7fc0d0
export GITHUB_CLIENT_SECRET=bb45d66c26b844604b6b03665f80ab8e76a781cf

`source .env`


use Ecto.Migration
def change do
  execute "create extension postgis", "drop extension postgis"
  alter table("events") do
    add



brew install postgis

# create extension postgis;

Use geography, not geometry, even if performance penalty but there is no projection involved.

=# create table mytable (pk serial primary key, geom geography(Point, 4326) );
=# create index idx_pt on mytable using gist (geometry);
=# insert into mytable (name, size, geom) values ('a', 1.0, 'point(1 10)');
=# select to_jsonb(mytable.\*) from mytable;


select \* from table1, table2
where st_distance(table1.the_geom,table2.the_geom) < 1000
order by table1.the_geom <-> table2.the_geom
limit 3


\set myvar 5
select :myvar + 1
6


WITH inputs (center, max_distance, date) as (
    values (point(45 1), 10000,31/12/2022)
)
SELECT a.id, b.id, ST_Distance(
    a.location, b.location)) distance
WHERE ST_Distance(a.location, b.location) < max_distance
FROM trees a, trees b
WHERE a.id < b.id
ORDER BY distance
LIMIT 1


```psql
BEGIN;
insert into users (name, email, inserted_at, updated_at) values ('toto', 'toto@mail.com', '01/10/2020', '01/10/2020');

select * from users;
id |     email     | name |     inserted_at     |     updated_at
----+---------------+------+---------------------+---------------------
  1 | toto@mail.com | toto | 2020-01-10 00:00:00 | 2020-01-10 00:00:00


execute("""
  alter table events add column coordinates geometry[];
""")

insert into events (owner, coordinates, inserted_at, updated_at) values (4, array[ST_GeomFromText('point(-1.57 47.2)',4326), ST_GeomFromText('point(-1.61 47.25)',4326)], '01/10/2000','01/10/2000')
;


execute("""
  select AddGeometryColumn('events', 'coordinates', 4326, 'LINESTRING', 2)
""")

insert into events (owner, coordinates, inserted_at, updated_at) values (1, ST_GeomFromText('LINESTRING(-1.5 47.2, -1.52 47.25)',4326), '01/10/2020', '01/10/2020');

select owner, ST_AsText(coordinates) as geom from events;
owner |               geom
-------+-----------------------------------
     1 | LINESTRING(-1.5 47.2,-1.52 47.25)

COMMIT;
```

Load into PostgreSQL using `psql` the file "test/events.sql" where we use a variable input

```
psql -d live_map_repo events.sql
 id |     email     | name
----+---------------+------
  1 | toto@mail.com |
  2 | bibi@mail.com |
(2 rows)

INSERT 0 1
INSERT 0 1
 owner |              coords
-------+-----------------------------------
     2 | LINESTRING(-1.5 47.2,-1.52 47.25)
     1 | LINESTRING(-1.5 47.2,-1.52 47.25)
(2 rows)
```


```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "LineString",
        "coordinates": [
          [-1.5, 47.2],
          [-1.5, 47.29]
        ]
      },
      "properties": {
        "ad1": "debut",
        "ad2": "fin",
        "date": "2022-10-02",
        "owner": "bibi",
        "status": ""
      }
    }
  ]
}
```