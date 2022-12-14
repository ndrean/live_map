# LiveMap

I have a solution that I would like to be challenged with.

I use Presence and the "presence_diff" handler to subscribe a new user to any other connected user "on mount".
I set up N(N+1)/2 subscriptions thus topics. The rule to design a topic is simply "1-3" if user_id 3 and user_id 1 are connected (the function is such that "set_topic(1,3) = set_tpoic(3,1)") .
I also need to save the list of topics in an ETS table to create only one topic between users 1 and 3, and also to unsubscribe the user when he leaves. Indeed, if a subscription is made twice, then we have a double rendering. Furthermore, when user 1 create the "1-3" subscription, then user 3 must also create the same subscrption.

Ok, nice, but this cannot be distributed, and why do I do this on mount? And not subscribe/unsubscribe "on-the-fly" when needed?

Maybe. I can create a special topic "subscriptions" to which any new user will subscribe and broadcast on it any new topic so the concerned user can match with his user-id and subscribe himself to the new topic so that both user will now be able to communicate. For example, any connected user will subscribe to the topic "subscriptions". If user 1 wants to talk to user 3, then user 1 subscribes to the topic "1-3" and boradcast on the topic "subscrptions" the message "1-3". Since user 3 receives this and his id matches the message, then he should also subscribe to the topic "1-3" and receive any message boradcasted on the "private topic "1-3".

You need to store these topics since if a user deconnects, then any private topics between him and other users must be deleted, otherwise you recreate an existing topic and they will receive double or more rendering.

NOTE: check tailwind.config.cjs and and in config tailwind
NOTE: caching raster tiles: <https://github.com/yagajs/leaflet-cached-tile-layer>

This is a little social web app that displays simple "events" on an interactive map with "soft" real-time updates. An event is a line with two endpoints; each endpoint has a popup that displays some informations about the point. The events are geolocated and displayed on a map.
The objective of this app is for each user to visualise and create events and interact with other users by asking to participate to an event.
The map discovers events when it is panned or zoomed.

It is inspired by [this talk](https://www.youtube.com/watch?v=xXWyOy9XdA8&t=255s) and some ideas are learned and solutions borrowed from [this book](https://pragprog.com/titles/puphoe/building-table-views-with-phoenix-liveview/), [this author](https://akoutmos.com/) and [this organisation](https://github.com/dwyl).

- [LiveMap](#livemap)
  - [Quick presentation of the app](#quick-presentation-of-the-app)
  - [Tooling](#tooling)
  - [Events and Markers](#events-and-markers)
  - [Database schema](#database-schema)
  - [Rendering of events on the map](#rendering-of-events-on-the-map)
      - [GeoJSON format](#geojson-format)
      - [Moving the map and query of the local events](#moving-the-map-and-query-of-the-local-events)
  - [Manage the invitations](#manage-the-invitations)
      - [Partial index](#partial-index)
      - [Multi on assoc](#multi-on-assoc)
  - [Schemaless date changeset and real time](#schemaless-date-changeset-and-real-time)
      - [Custom error tag](#custom-error-tag)
  - [General search with View](#general-search-with-view)
      - [Generate a table from the map](#generate-a-table-from-the-map)
      - [Custom datalist input and `phx_debounce`](#custom-datalist-input-and-phx_debounce)
  - [Postgis setup](#postgis-setup)
  - [Leaflet setup](#leaflet-setup)
    - [Leaflet MapHook code](#leaflet-maphook-code)
  - [Misc notes](#misc-notes)

## Quick presentation of the app

When a user opens the app, the map is directed to his current position (if geolocation is enabled). He can also enter the desired location in a form included in the map. Once arrived, he visualises the existing events nearby. When the user pans, zooms or navigates in the map, new events are discovered as we run a query to get these events depending on the coordinates and the radius of the map.

A user can create an event which is a journey from a point A to a point B. It is represented on a map by a line with two markers. Each marker has a popup that displays the name of the owner, the date of the event and the address at this vertex.

A user can ask to participate to an event via a button. This triggers a notification and confirmation process, all done via mail. Note that every user has to be registered and an email address is obtained with a direct social media login.

The app is a single page app with a LiveView. The map is a `live-component` and the date forms, and the tables are functional components.
One point to mention is when you use variables in a component: the compiler asks you to pass them instead into the assigns for change tracking.

## Tooling

The [Leaflet.js](https://leafletjs.com/) library is our "raster tile client".

- raster tiles server: Leaflet fetches online png files from OpenStreetMap server and stitches this collection of images. It is recommended to cache and/or have your own tile server. For production usage, [other suppliers](https://switch2osm.org/providers/) should be considered.

- geolocation and reverse geocoding. We query the [nominatim](https://nominatim.org/release-docs/latest/api/Overview/) server to "reverse-geocode", meaning get the address at the marker location and populate the popup with it. When the marker is dragged to another position, a new query is triggered. We also query the `nominatim` server to geolocate an address, meaning typing an address, find a match in the database and get the coordinates of this point. The nominatim service is limited to [one query per second](https://operations.osmfoundation.org/policies/nominatim/). No "onChange" search is allowed for the geolocation neither.

> To overcome this, a rate limiter is set using a "token bucket" technic.

Two other optimisation are possible: caching raster tiles or using **vector tiles**.

The database is a Postgres database with the **Postgis** extension enabled.
We use the **geography** version. We perform a "[nearest neighbours] (https://postgis.net/workshops/postgis-intro/knn.html)" search to the current location with regards to the dimension of the map. See also Crunchy data [post](https://www.crunchydata.com/blog/a-deep-dive-into-postgis-nearest-neighbor-search).

We use a spatial index, the [GIST](https://postgis.net/docs/using_postgis_dbmanagement.html#Create_Spatial_Table) format to improve the speed of search. We also limit the period of the retrieved events.
The config for Postgis is [down here](#postgis-setup).

The map and the table are "soft" live updated whenever a new event is created by a user, and `Presence` is enabled too.

[:arrow_up:]()

## Events and Markers

You have two kind of markers:

- markers as vertices of events retrieved from the database,

- markers created by clicking on the map, to build a new event.

When you create a marker, a table appears below to set the date and save and broadcast it. You can move/drag, or delete the marker while the event is not saved.

> This "geocoding" request is sent by the front-end. There exists an Elixir library [geocoder](https://github.com/DaoDeCyrus/geocoder) that can handle this server-side. This is not used here as the data flow would be much more complicated and less performant in this case. Indeed, on click client-side, we send the coordinates to the geocoder to receive the data, store it in an object, and if ok, send and save the object in the database. If we had to do this server-side, we would need a GenServer to hold a state and handlers to interact with the geocoder and client.

An example of an event creation:

![downwind](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/umukgs40ho9w841zqc9h.png)

with the ephemeral table:

![Event table](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/wkpwg9e8xr29015z40m8.png)

The client code is [here](#leaflet-maphook-code)

[:arrow_up:]()

## Database schema

The ER Diagram of the database. This schema is generated by the library [Ecto_ERD](https://github.com/fuelen/ecto_erd/).

![ERD project](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/4ggpvgysqbcqz4aioiqm.png)

[:arrow_up:]()

## Rendering of events on the map

#### GeoJSON format

We use the [GeoJson format](https://macwright.com/2015/03/23/geojson-second-bite.html). This [repo](https://github.com/tmcw/awesome-geojson) links to some GeoJson utilities.
Leaflet and PostGIS have primitives to work verry easily with a collection of GeoJSON objects.

```json
{
  "type": "FeatureCollection",
  "features": [
    {..."features" objects }
  ]
}
```

Each feature in our case is a "LineString". It has properties related his two vertices.

```json
{
  "type": "Feature",
  "geometry": {
    "type": "LineString",
    "coordinates": [
      [-1.5, 47.2],
      [-1.52, 47.29]
    ]
  },
  "properties": {
    "ad1": "start point address",
    "ad2": "end point address",
    "date": "01/09/2022",
    "owner": "me@mail.com"
  }
}
```

The Postgres **Postgis** extension is used with an [indexed](http://postgis.net/workshops/postgis-intro/indexing.html) database. We use the Elixir packages [geo](https://hexdocs.pm/geo/1.1.0/Geo.html) and [geo_postgis](https://github.com/bryanjos/geo_postgis) that enables us to use a field of type "geography".

The data corresponding to a "feature" is a record of the table "events".

```elixir
use Ecto.Migration
  create table(:events) do
      add :user_id, references(:users)
      add :distance, :float
      add :ad1, :text
      add :ad2, :text
      add :date, :date
    end

  execute("CREATE EXTENSION IF NOT EXISTS postgis")
  execute("ALTER TABLE events ADD COLUMN coordinates geography(LINESTRING, 4326);")
  execute("CREATE INDEX  events_gix ON events USING GIST (coordinates);")
  end
```

We don't use JSONB but instead a "flat" table structure. The table `events` is parsed into an Elixir struct that we named "GeoJSON", used later.

#### Moving the map and query of the local events

We have a listener on the map moves, whether pan, zoom or navigate to. It mutates a local store - a JS object - named `movingmap`. We send the centre and radius of the current displayed map as parameters to a query to retrieve the nearby events. When you pan, zoom, navigate in the map (the latter via the search form included in the map), a new centre and radius are calculated and the map is updated.

```js
map.on("moveend", updateMapBounds);
function updateMapBounds() {
... mutate movingmap...
}
```

The object is "proxied" (Javascript `proxy`) in the front-end where we save the centre and radius of the displayed map. It gets updated/mutated by the callback of the listener "moveend"

```js
const movingmap = proxy({
  center: [],
  distance: 10_000,
});
```

We subscribe to mutations (we used **Valtio**), and push this data to the server if any:

```js
subscribe(movingmap, () => {
  this.pushEventTo("#map", "postgis", {
    movingmap,
  });
});
```

Server-side, the handler is:

<details><summary> Event handler code </summary>

```elixir
def handle_event("postgis", %{"movingmap" => moving_map}, socket) do
    user_id = socket.assigns.user_id
    # retrieve from ETS the last value for this user
    [{user_id, now}] = :ets.lookup(:limit_user, user_id)
    time_limit = Time.add(now, 1, :second)

    results =
      case Time.compare(Time.utc_now(), time_limit) do
        :gt ->
          Task.Supervisor.async(LiveMap.TSup, fn ->
            %{"distance" => distance, "center" => %{"lat" => lat, "lng" => lng}} = moving_map
            # query for the nearby features collection
            LiveMap.Repo.features_in_map(lng, lat, String.to_float(distance))
            |> List.flatten()
          end)
          |> then(fn task ->
            # update with new time for this user
            :ets.insert(:limit_user, {user_id, Time.utc_now()})
            case Task.await(task) do
              nil ->
                Logger.warn("Could not retrieve events")
                nil

              result ->
                result
            end
          end)
        _ ->
          nil
     end

    {:noreply, push_event(socket, "update_map", %{data: results})}
end

```

</details>

The function "features_in_map" is the Postgres query below. It is much easier to use plain SQL and build a JSON response in a GeoJSON format for `Postgrex` to handle it.

```elixir
def features_in_map(lng, lat, distance, date_start \\ default_date(0), date_end \\ default_date(30) do

    query = [
      "SELECT json_build_object(
      'type', 'FeatureCollection',
      'features', json_agg(ST_AsGeoJSON(t.*)::json)
      )
      FROM (
      SELECT users.email, events.ad1, events.ad2, events.date, events.coordinates, events.distance, events.color,
      coordinates  <-> ST_MakePoint($1,$2) AS sphere_dist
      FROM events
      INNER JOIN users on events.user_id = users.id
      WHERE ST_Distance(ST_MakePoint($1, $2),coordinates)  < $3
      AND events.date >= $4::date AND events.date <$5::date
      )
      AS t(email, ad1, ad2, date, distance, color, coordinates);
      "
    ]

    case Ecto.Adapters.SQL.query(Repo, query, [lng, lat, distance, date_start, date_end]) do
      {:ok, %Postgrex.Result{rows: rows}} -> rows


      {:error, %Postgrex.Error{postgres: %{message: message}}} ->
        Logger.error(message)
    end
  end

defp default_date(d), do: Date.utc_today() |> Date.add(d)
```

There several steps here:

- the "costly" query has a very simple rate limiter per user, at the rate of one per second to avoid "over-fetching" for small moves of the map. We instantiate in the LiveView `mount` a tuple `{user_id, Time.utc_now}` saved in an ETS table instantiated with the app. When the handler is triggered, the query can run if the current time is at least 1 second older than the one in ETS. When this is the case, we save in ETS the time when the user ran the query.
- in the `features_around` function, we query for the nearest neighbours. We used the **distance operator** [<->](https://postgis.net/docs/geometry_distance_knn.html) which accelerates the query in combination with the GIST index.
- return data in GeoJSON format with [this function](https://postgis.net/docs/ST_AsGeoJSON.html).

The data is pushed to the front-end where we have a listener. It will iterate over the features array

```js
this.handleEvent("udpate_features", ({ data }) => handleData(data));
```

The callback `handleData` will parse the GeoJSON which contains all the needed information. We know it is of type "linestring" with coordinates and we can set the properties on each vertex in a popup (owner, date, address). We also have settings for the line (with settings):

```js
function handleData(data) {
  if (data) {
    L.geoJSON(data, {
      // iterate over each feature
      onEachFeature: onEachFeature,
      // settings for the line
      style: lineStyle,
    }).addTo(datagroup);
  }
}

// iteration
function onEachFeature(feature, layer) {
  const { ad1, ad2, owner, date, color } = feature.properties;
  const [start, end] = layer.getLatLngs();
  addCircleMarker(start, ad1, owner, date, color);
  addCircleMarker(end, ad2, owner, date, color);
}

// define the marker as a circle and add a popup
function addCircleMarker(pos, addr, owner, date, color) {
  L.circleMarker(pos, { radius: 10, color })
    .bindPopup(info(addr, owner, date))
    .addTo(datagroup);
}

// create the html in the popup
function info(addr, owner, date) {
  const evtDate = new Date(date).toDateString();
  return `
     <h4>${owner}, the ${evtDate}</h4>
     <h5>${addr}</h5>
   `;
}
```

[:arrow_up:]()

## Manage the invitations

The process is similar to a password-less login. In fact, the login is via a social media login (which we don't describe) thus we get the user's email which is supposed to be verified. All the flow below will use emails and the process is described in the diagram below:

![flow participation](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/5ooil3d759vq8ng8hg0c.png)

#### Partial index

The migration of the table "event_participants" contains two unique indexes: one that scopes the user per event, and one [partial index](https://www.postgresql.org/docs/current/indexes-partial.html) - conditional - that constraints the status "owner" to be unique: no more than one "owner" when scoped by event.

```elixir
use Ecto.Migration
def change do
  create table(:event_participants) do
    add :user_id, references(:users)
    add :event_id, references(:events)
    add :status, :event_status, null: false
    add :mtoken, :string
  end

  create unique_index(:event_participants, [:event_id, :user_id], name: :evt_usr)

  create unique_index(:event_participants, [:event_id],
      where: "status = 'owner'", name: :unique_owner
  )
end

use Ecto.Schema
  schema "event_participants" do
    belongs_to :user, LiveMap.User
    belongs_to :event, LiveMap.Event
    field :ptoken, :string, default: nil
    field :status, Ecto.Enum, values: [:owner, :pending, :confirmed]
  end
```

These db rules are transposed into a changeset:

```elixir
def changeset(%__MODULE__{} = event_participants, attrs) do
  event_participants
  |> cast(attrs, [:user_id, :event_id, :mtoken, :status])
  |> validate_required([:status])
  |> unique_constraint([:user_id, :event_id], name: :evt_usr)
  |> unique_constraint([:event_id], where: "status = 'owner'", name: :unique_owner)
  |> foreign_key_constraint(:user_id)
  |> foreign_key_constraint(:event_id)
  end
```

#### Multi on assoc

When a user creates an event, a new "event_participants" is created in the same transaction. The user's status in the event is "owner".

```bash
# record in "event_participants"
[event_id, owner_id, "owner", nil]
```

and the context "new" function is:

```elixir
def new(params) do
  Ecto.Multi.new()
  |> Ecto.Multi.insert(:evt, Event.changeset(%Event{}, params))
  |> Ecto.Multi.run(:ep, fn repo, %{evt: event} ->
    repo.insert(
      EventParticipants.changeset(%EventParticipants{}, %{
        event_id: event.id,
        user_id: params.user_id,
        status: :owner
      })
    )
  end)
  |> Repo.transaction()
end
# -> {:ok, %{ep: ..., evt: ...}}
```

With the constraints, the owner is unique, but there can be many users, whose status are "pending" xor "confirmed" (only one status per user), depending if the owner responded. The flowsheet is explained in the diagram above.

When a registered user makes a request to participate to an event, we grab the event_id and create a new record in the "event_participants" table and generate a `Phoenix.Token` from the data: **event_id=xxx&user_id=xxx**:

```
Phoenix.Token(..., "event_id=xxx&user_id=xxx**")
SFMyNTY.g2gDbQAAABR...

# record in "event_participants"
[event_id, owner_id, "pending", SFMyNTY.g2gDbQAAABR...]
```

With these two fields (event_id, user_id), we find the owner and send him a mail with a "magic" link with this token. It invites him to follow the link to "confirm" the event to the demander.

When the owner clicks on the link, it hits an endpoint where we `verify` and `decode_query` the token. If it is valid, this gives the "event_id" and "user_id". We can retrieve a token from the DB and check for equality. If everything is correct (i.e. not ":expired" or ":invalid"), the status is updated, the token destroyed and a confirmation mail is sent to the user.

```
{:ok, string} = Phoenix.Token.verify(..., token,...)
%{"event_id" => event_id, "user_id" => user_id} = URI.decode_query(string)
[...]
#=> send mail

[event_id, user_id, "confirmed", nil]
```

This process is run in a `Task` and uses **Swoosh** (no Oban nor a lamdba for the moment).

[:arrow_up:]()

## Schemaless date changeset and real time

Here is described the "save event" form in combination with "real-time" update.

Real-time is almost a free lunch with `Phoenix.PubSub`. Firstly subscribe in the LiveView `mount/3`:

```elixir
def mount(_, %{"email" => email, "user_id" => user_id} = _session, socket) do
  if connected?(socket), do: LiveMapWeb.Endpoint.subscribe("event")
  {:ok, assign(socket, current: email, user_id: user_id)}
end
```

To save an event, there is a form here the user sets the date of an event in a `live_component`. We use a schemaless changeset: the date is required and only future dates are allowed.

```elixir
import Ecto.Changeset
alias LiveMap.DatePicker

defstruct [:event_date]
  @types %{event_date: :date}

def changeset(%DatePicker{} = date, attrs \\ %{}) do
    {date, @types}
  |> cast(attrs, Map.keys(@types))
  |> validate_required([:event_date])
  |> validate_future()
end

defp validate_future(%{changes: %{event_date: date}} = changeset) do
  case Date.compare(date, Date.utc_today()) do
    :lt ->
      add_error(changeset, :event_date, "Future dates only!")

    _ ->
      changeset
  end
end

defp validate_future(changeset), do:  changeset
```

The form is a child `:live_component`.

We used a GeoJson in an Elixir struct. It just needs a setter to populate an instance from an Event record:

```elixir
defmodule LiveMap.GeoJSON do
  defstruct type: "Feature",
    geometry: %{type: "LineString", coordinates: []},
    properties: %{ad1: "", ad2: "", date: Date.utc_today(), user: nil, distance: 0
    }
```

It remains to write the message handler that pushes the GeoJSON to the client. Since the message is broadcasted, it is the LiveView that holds it and every connected user will get the message:

```elixir
def handle_info(%{topic: "event", event: "new publication",
   payload: %{geojson: geojson}}, socket), do:
    {:noreply, push_event(socket, "new pub", %{geojson: geojson})}
```

In the front-end, there is a corresponding listener that consumes GeoJSON objects:

```js
this.handleEvent("new pub", ({ geojson }) => {
  clearEvent();
  handleData(geojson);
});
```

#### Custom error tag

If we want to change the default class, for example to add some margin etc, we have to modify the "/views/error_helpers.ex" file to make the `content_tag` able to read the key `:class` (while still using the default value):

```elixir
def error_tag(form, field, class \\ [class: "invalid-feedback"]) do
    Enum.map(Keyword.get_values(form.errors, field), fn error ->
    content_tag(:span, translate_error(error),
      class: Keyword.get(class, :class),
      phx_feedback_for: input_name(form, field)
    )
  end)
end
```

[:arrow_up:]()

## General search with View

#### Generate a table from the map

When the user is at a given location, he can query to get the events at this location given a future time frame. The format of the data is:

```
[event_id, map_owner, map_demanders_array || map_confirmed_array ]

-> [6, %{"confirmed" => ["demander@gmail.com"], "owner" => ["ownern@yahoo.fr"]}, %{"date" => "2022-10-10"}]
```

To get this form, you can run a query `Repo.query()` like:

```sql
 WITH geo_events AS (
   SELECT coordinates  <-> ST_MakePoint($1,$2) AS sphere_graphy, events.id,  events.date, ep.user_id, u.email, ep.status
   FROM events
   JOIN event_participants ep ON ep.event_id = events.id
   JOIN users u ON u.id = ep.user_id
   WHERE date >= $4::date AND date <= $5::date
   AND ST_Distance(ST_MakePoint($1,$2),events.coordinates)  < $3
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
;
```

This produces a list of lists which can easily be passed into a table. The structure is:

```elixir
[
  event_id,
  %{map of status:[users_per_status]},
  %{date_map}
]

[
  88,
  %{
    "confirmed" => ["me@gmail.com", "her@could.com"],
    "owner" => ["you@yahoo.com"],
    "pending" => ["any@com"]
  },
  %{"date" => "2022-11-08"}
]
```

#### Custom datalist input and `phx_debounce`

The relevant part of the dos is [here](https://hexdocs.pm/phoenix_live_view/form-bindings.html#form-events). With the `.form` component, an individual input can use its own change event. We used an individual `phx_change` and `phx_debounce` action to populate the datalist with an `ilke` search on user input.

The search function:

```elixir
# module User.ex

def search(string) do
  like = "%#{string}%"
  from(u in User, where: ilike(u.email, ^like))
  |> Repol.all()
end
```

is used in an event handler below:

```elixir
def handle_event("search", %{"form" => %{"user" => string}}, socket) do
    datalist = LiveMap.User.search(string) |> Enum.map(& &1.email)
    IO.inspect(datalist, label: "datalist")
    {:noreply, assign(socket, users: datalist)}
  end
```

which is triggered on `phx_change` by the input element below of the form

```elixir
<%= text_input(f, :user,
  phx_change: "search",
  phx_target: @myself,
  phx_debounce: "500",
  list: "datalist",
  placeholder: "enter an email") %>

  <%= datalist_input(id: "datalist") do %>
    <%= for user <- @users do %>
      <%= option_input(user) %>
    <% end %>
  <% end %>
```

The output in the terminal indeed shows:

```bash
Event: "search"
Parameters: %{"_target" => ["form", "user"], "form" => %{"user" => "xxxx"}
```

By default no datalist element is provided. You need to add a custom helper named "InputHelpers" here to be able to use a "datalist_input":

```elixir
defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML
      [...]
      import LiveMapWeb.InputHelpers
    end
  end
```

and build a helper on the same model as a "button" to accept an inner slot (cf "/deps/phoenix_Html/lib/phoenix_Html/form.ex")

```elixir
defmodule LiveMapWeb.InputHelpers do
  use Phoenix.HTML

  def datalist_input(opts, [do: _] = block_options) do
    content_tag(:datalist, opts, block_options)
  end

  def option_input(user) do
    content_tag(:option, "", value: user)
  end
end
```

## Postgis setup

Install the extension [geo_postgis](https://github.com/bryanjos/geo_postgis) for "postgrex":

```elixir
use Mix.Project

  {:jason, "~> 1.4"},
  {:geo, "~> 3.4"},
  {:geo_postgis, "~> 3.4"}
```

and configure it to use the parser "Jason". Since we are using Ecto, we follow the guide:

```elixir
#configs.exs

config :geo_postgis,
  json_library: Jason

config :live_map, LiveMap.Repo,
  database: "live_map_repo",
  [...]
  adapter: Ecto.Adapters.Postgres,
  types: LiveMap.PostgresTypes
```

```elixir
# lib/postgres_types
Postgrex.Types.define(
  LiveMap.PostgresTypes,
  [Geo.PostGIS.Extension] ++ Ecto.Adapters.Postgres.extensions(),
  json: Jason
)
```

Lastly, you need to declare the extension in a migration.

[:arrow_up:]()

## Leaflet setup

You need to tell Esbuild that you use "png" images for the markers.

```elixir
# config/config.exs
config :esbuild,
  default: [
    args: ~w( --bundle --target=es2020 --loader:.png=dataurl ...)
  ]
...
```

You also need to load the CSS and set the height and width to the div that holds the map to display:

```css
/* app.css */
@import "leaflet/dist/leaflet.css";
@import "leaflet-control-geocoder/dist/Control.Geocoder.css";

#mymap {
  height: 400px;
  width: 100%;
}
```

To render the map, add two bindings:

- `phx-update="ignore"` to let `Leaflet` update tiles without interacting with LiveView (see [docs](https://hexdocs.pm/phoenix_live_view/dom-patching.html#content)),
- and `phx-hook` to your custom "hook":

```elixir
use Phoenix.LiveComponent
def render(assigns) do
  ~H"""
    <div id="mymap"
      phx-update="ignore"
      phx-hook="MapHook"
    ></div>
  ""
end
```

To minimise the initial load, the `Leaflet` library is loaded async. You build an object with the same name as in your `phx-hook`:

```js
async function loader() {
  return Promise.all([
    import("leaflet"),
    import("leaflet-control-geocoder"),
  ]);
}
[...]
export const MapHook = {
  async mounted() {
    const [L, { geocoder }, { default: icon }, { default: iconShadow }]
      = await loader();

    const map = L.('mymap', { renderer: L.canvas() }).setView(...)
  }
}
```

This "hook" in attached to the LiveSocket object.

```js
// assets/app.js
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: { MapHook },
});
```

Since `Leaflet` is purely a client library, all the events are stored in a local store.
We used 3 abstractions with local stores:

- a store for the map's radius and center coordinates,
- a store for the event creation that will eventually be saved to be database,
- a store to display the events fetched and updated from the database.

Each time the map is panned or zoomed, this triggers a "moveend" event. With the new coordinates and radius, the corresponding events are fetched from the DB and rerendered in a fresh layer to avoid a build-up in the canvas layer.

When an event is created, we fetch the geolocaized address from the `nominatim` database. The user can drag-and-drop the marker to set a new location and the data is re-fetched and updated.

[:arrow_up:]()

### Leaflet MapHook code

## Misc notes

- Schemaless changset
  <https://elixirfocus.com/posts/ecto-schemaless-changesets/>

- update the map when running the query ??
- modal for participants status by event (list of names for pending/confirmed instead of a <td> for readability)
- more queries in the table: selection by user and by status
- for fun: add a svg graph to show distances per user
- add a serverless chat?

<https://www.codejam.info/2021/11/elixir-intercepting-phoenix-liveview-events-javascript.html>
