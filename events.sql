BEGIN;

SELECT * FROM event_participants;

-- make a readable output of the table "events"
SELECT user_id, ad1, ad2, date, ST_AsText(coordinates) AS coords FROM events;

-- output the field 'ad1" given a match on the geometry field
SELECT  ad1 FROM events WHERE  coordinates = st_geomfromtext('linestring(-1 41, -1 40)',4326);
--     ad1
-- -----------
--  3d ad1

-- transform each row of the table events into a GeoJSON object
SELECT ST_AsGeoJSON(t.*)
FROM (
    SELECT users.email, events.ad1, events.ad2, events.date, events.coordinates FROM users
    INNER JOIN events on events.user_id = users.id 
)
AS t(email, ad1, ad2, date, coordinates);


-- transform the table "events" into a collection of GeoJson objects
SELECT json_build_object(
    'type', 'FeatureCollection',
    'features', json_agg(ST_AsGeoJSON(t.*)::json)
    )
FROM (
    SELECT users.email, events.ad1, events.ad2, events.date, events.coordinates FROM users
    INNER JOIN events on events.user_id = users.id 
)
AS t(email, ad1, ad2, date, coordinates);


-- Calculate the distance (in **degrees**) from the point (-2 40) to the given segment 
SELECT ST_Distance(
    'srid=4326;point(-2 40)'::geometry,
    'srid=4326;linestring(-1 40, -1 41)'::geometry)
AS one_degree;
--  one_degree
---------
--    1

-- Calculate the distance (in **meters**) from the point (-2 40) to the given segment 
-- https://postgis.net/docs/ST_DistanceSphere.html
SELECT ROUND(
    CAST(ST_DistanceSphere(
        'SRID=4326;POINT(-2 40)'::geometry,
        'SRID=4326;LINESTRING(-1 40, -1 41)'::geometry
        )
    AS numeric),
0) AS one_degree_via_great_circle_geometry;
-- one_degre_via_great_circle_geometry
-- ---------------------------
--                      85179


SELECT ROUND(
    CAST( ST_Distance(
        'srid=4326;point(-2 40)'::geography, 
        'srid=4326;linestring(-1 40, -1 41)'::geography)
    AS numeric),
0) AS one_degree_via_st_distance_geography;
-- one_degree_via_st_distance_geography
-- ---------------------------
--                      85392

SELECT MIN(ST_Distance(ST_MakePoint(-2,40), coordinates)) from events;
--  min
--------------
--  85392.06557542

-- version if type geometry is used (in migration)
-- SELECT *, (ST_DistanceSphere('SRID=4326;POINT(-1 45)'::geometry,coordinates)) AS dist FROM events
-- WHERE (ST_DistanceSphere('SRID=4326;POINT(-1 45)'::geometry,coordinates)) < 450000
-- AND date < '2022-02-01'
-- ORDER BY dist;

EXPLAIN SELECT events.id,user_id, users.email, ad1, ad2, date, ST_AsText(coordinates),  coordinates  <-> ST_MakePoint(-1,40) AS sphere_graphy 
FROM events
INNER JOIN users ON user_id = users.id 
WHERE ST_Distance('SRID=4326;POINT(-1 40)'::geography,coordinates)  < 200000
AND date < '2022-04-01'
ORDER BY sphere_graphy ASC;

EXPLAIN SELECT id, user_id, ad1, ad2, date, ST_AsText(coordinates),  coordinates  <-> ST_MakePoint(-1,40) AS sphere_graphy 
FROM events
WHERE ST_Distance('SRID=4326;POINT(-1 40)'::geography,coordinates)  < 200000
AND date < '2022-04-01'
ORDER BY sphere_graphy ASC;

-- SELECT id, owner, ad1, date, ST_AsText(coordinates), (ST_Distance('SRID=4326;POINT(-2 40)'::geometry,coordinates)) AS ST_dist_geom FROM events
-- WHERE (ST_Distance('SRID=4326;POINT(-2 40)'::geometry,events.coordinates)) < 2
-- -- AND date < '2022-01-01'
-- ORDER BY ST_dist_geom;


SELECT json_build_object(
    'type', 'FeatureCollection',
    'features', json_agg(ST_AsGeoJSON(t.*)::json)
    )
FROM (
    SELECT users.email, events.ad1, events.ad2, events.date, events.coordinates,
    coordinates  <-> ST_MakePoint(-1,40) AS sphere_dist
    FROM events
    INNER JOIN users on events.user_id = users.id 
    WHERE ST_Distance('SRID=4326;POINT(-1 40)'::geography,coordinates)  < 200000
    AND date < '2021/12/01'
)
AS t(email, ad1, ad2, date, coordinates);



-- run this file with: `psql -d live_map_dev -f test/events.sql`

