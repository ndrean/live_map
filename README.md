# LiveMap

TODO: explain!!
- update the map when running the query ??
- modal for participants status by event (list of names for pending/confirmed instead of a <td> for readability) 
- more queries in the table: selection by user and by status
- for fun: add a svg graph to show distances per user
- add a serverless chat?





This is a little social web app that displays simple "events" on an interactive map with "soft" real-time updates. It is inspired by [this talk](https://www.youtube.com/watch?v=xXWyOy9XdA8&t=255s) and some ideas are learned and solutions borrowed from [this book](https://pragprog.com/titles/puphoe/building-table-views-with-phoenix-liveview/), [this author](https://akoutmos.com/) and [this organisation](https://github.com/dwyl). 

- [0. Quick presentation](#quick-presentation-of-the-app)

- [1. Tooling](#tooling)

- [2. Events and Markers](#events-and-markers)

- [3. Database Schema](#database-schema)

- [4. Rendering events when moving the map](#rendering-of-events-on-the-map)

- [5. Invitation management process](#manage-the-invitations)
    - [partial index](#partial-index)
    - [Multi on association](#multi-on-assoc)

- [6. Schemaless changeset example with the date validator and "reat-time"](#schemaless-date-changeset-and-real-time)
    - [Customer error_tag](#custom-error-tag)

- [7. Queries]
    - [Generate a table from the map](#generate-a-table-from-the-map)
    - [Custom datalist input and `phx_debounce`](#custom-datalist-input-and-phx_debounce) 
- [8. Postgis setup](#postgis-setup)

  11.[Table and Queries for user data]

- [Leaflet setup and code](#leaflet-setup)

## Quick presentation of the app

When a user opens the app, the map is directed to his current position (if geolocation is enabled). He can also enter the desired location in a form included in the map. Once arrived, he visualises the existing events nearby. When the user pans, zooms or navigates in the map, new events are discovered as we run a query to get these events depending on the coordinates and the radius of the map.

A user can create an event which is a journey from a point A to a point B. It is represented on a map by a line with two markers. Each marker has a popup that displays the name of the owner, the date of the event and the address at this vertex.

A user can ask to participate to an event via a button. This triggers a notification and confirmation process, all done via mail. Note that every user has to be registered and an email address is obtained with a direct social media login.

The app is a single page app with a LiveView. The map is a `live-component` and the date forms, and the tables are functional components.
One point to mention is when you use variables in a component: the compiler asks you to pass them instead into the assigns for change tracking. 


## Tooling

The [Leaflet.js](https://leafletjs.com/) library is our "raster tile client": it fetches online png files from a server - OpenStreetMap - and stitches this collection of images. The immediate optimisation  would be to use **vector tiles** instead and the more powerful library [maplibre](https://maplibre.org/maplibre-gl-js-docs/api/). The Leaflet setup and code is [here](#leaflet-setup)


The database is a Postgres database with the **Postgis** extension enabled. We use the **geography** version. We perform a "[nearest neighbours] (https://postgis.net/workshops/postgis-intro/knn.html)" search to the current location with regards to the dimension of the map. See also Crunchy data [post](https://www.crunchydata.com/blog/a-deep-dive-into-postgis-nearest-neighbor-search).

We use a spatial index, the [GIST](https://postgis.net/docs/using_postgis_dbmanagement.html#Create_Spatial_Table) format to improve the speed of search. We also limit the period of the retrieved events and a rate limiter.
The config for Postgis is [down here](#postgis-setup).

The map and the table are "soft" live updated whenever a new event is created by a user, and `Presence` is enabled too.


[:arrow_up:]()

##  Events and Markers


You have two kind of markers:

- markers as vertices of events retrieved from the database, 

- markers created by clicking on the map, to build a new event. 


When you create a marker, a table appears below to set the date and save and broadcast it. You can move/drag, or delete the marker while the event is not saved. We query the [nominatim](https://nominatim.org/release-docs/latest/api/Overview/) server to get the address at the marker and populate the popup with it. The nominatim service is limited to [one query per second](https://operations.osmfoundation.org/policies/nominatim/). When the marker is dragged to another position, a new query is triggered. All other servers (Esri/ArcGis, Mapbox or Google) require an API key and pay-per-usage.

> this "geocoding" request is sent client-side. There exists an Elixir library [geocoder](https://github.com/DaoDeCyrus/geocoder) that can handle this server-side. This is not used here as the data flow would be much more complicated and less performant in this case. Indeed, on click client-side, we send the coordinates to the geocoder to receive the data, store it in an object, and if ok, send and save the object in the database. If we had to do this server-side, we would need a GenServer to hold a state and handlers to interact with the geocoder and client.

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

We use the [GeoJson format](https://macwright.com/2015/03/23/geojson-second-bite.html). This [repo](https://github.com/tmcw/awesome-geojson) links to some GeoJson utilities. Leaflet has primitives to work easily with a collection of GeoJSON objects. 

```json
{
  "type": "FeatureCollection",
  "features": [
    {..."features" objects }
  ]
}
```

Each feature is a "LineString" with properties related his two vertices. 

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

The data corresponding to a feature is a record of the table "events".

```elixir
use Ecto.Migration
  create table(:events) do
      add :user_id, references(:users)
      add :distance, :float
      add :ad1, :text
      add :ad2, :text
      add :date, :date
      # add :coordinates, :geography[]
    end

  execute("CREATE EXTENSION IF NOT EXISTS postgis")
  execute("ALTER TABLE events ADD COLUMN coordinates geography(LINESTRING, 4326);")
  execute("CREATE INDEX  events_gix ON events USING GIST (coordinates);")
  end
```

We parse the "events" table into an Elixir struct named "GeoJSON" here, used later.

We listen to the map moves  - whether pan, zoom or navigate to - and mutate a JS object `movingmap`. We send the centre and radius of the current displayed map as parameters to a query to retrieve the nearby events. When you pan, zoom, navigate in the map (the latter via the search form included in the map), a new centre and radius are calculated and the map is updated.  

```js
map.on("moveend", updateMapBounds);
function updateMapBounds() {
... mutate movingmap...
}
```

The object is "proxied" (Javascript `proxy`) in the front-end where we save the centre and radius of the displayed map. It gets updated/mutated by the callback of the listener "moveend" 

```js
const movingmap = proxy({ center: [], distance: 10_000 });
```

We subscribe to mutations (we used **Valtio**), and push this data to the server if any:

```js
subscribe(movingmap, () => {
      this.pushEventTo("#map", "postgis", { movingmap });
 });
```

Server-side, the handler is:

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

The function "features_around" is the Postgres query below: 
 
```elixir
def features_around(lng, lat, distance, date_start \\ default_date(0), date_end \\ default_date(30) do

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

    case Repo.query(query, [lng, lat, distance, date_start, date_end]) do
      {:ok, %Postgrex.Result{rows: rows}} -> rows
        

      {:error, %Postgrex.Error{postgres: %{message: message}}} ->
        Logger.error(message)
    end
  end

defp default_date(d), do: Date.utc_today() |> Date.add(d)
```

There several steps here:
- the "costly" query has a very simple rate limiter per user, at the rate of one per second to avoid "over-fetching" for small moves of the map. We instantiate  in the LiveView `mount` a tuple `{user_id, Time.utc_now}` saved in an ETS table instantiated with the app. When the handler is triggered, the query can run if the current time is at least 1 second older than the one in ETS. When this is the case, we save in ETS the time when the user ran the query. 
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
};
```

[:arrow_up:]()

##  Manage the invitations

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

When a user creates an event, he is the "owner". A new event is created along with an "event_participants". The status is set to the value "owner". 

```
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


## Schemaless date changeset and  real time

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

The form is a child `:live_component`:

```elixir
def update(assigns, socket) do
  len = assigns.event["coords"] |> length()
  socket = assign(socket, :len, len)
  {:ok, assign(socket, assigns)}
end

# display the form only when two markers are displayed
def render(%{len: len} = assigns) when len>1 do
  ~H"""
  <div>
  <.form :let={f} for={@changeset} id="form" phx-submit="up_date" phx-target={@myself} class="...">
      <%= submit "Update", class: "..." %> 
      <%= date_input(f, :event_date, id: "date" %>
      <%= error_tag(f, :event_date), class: "m-1 ..." %>
  </.form>
  </div>
  """
end

def render(assigns) do
  ~H"""
    <div></div>
  """ 
end

def handle_event("up_date", %{"date_picker" => %{"event_date" => date}} = _p, socket) do
    changeset = DatePicker.changeset(%{"event_date" => date})

    case changeset.valid? do
      true ->
        %{user_id: user_id, place: place} = socket.assigns
        create_event(%{"place" => place, "date" => date, "user_id" => user_id}, socket)

      false ->
        {:error, changeset} = Ecto.Changeset.apply_action(changeset, :insert)
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def create_event(%{"place" => place, "date" => date, "user_id" => user_id}, socket) do
    owner_id = user_id

    Task.Supervisor.async_nolink(LiveMap.EventSup, fn ->
      LiveMap.Event.save_geojson(place, owner_id, date)
    end)
    |> Task.await()
    |> then(fn geojson -> handle_geojson(geojson, socket) end)
  end

  defp handle_geojson(%LiveMap.GeoJSON{} = geojson, socket) do
    :ok = LiveMapWeb.Endpoint.broadcast!("event", "new publication", %{geojson: geojson})
    {:noreply, put_flash(socket, :info, "Event saved")}
  end

  defp handle_geojson({:error, _reason}, socket),
    do: {:noreply, put_flash(socket, :error, "Internal error")}

end
```


We used a GeoJson in an Elixir struct. It just needs a setter to populate an instance from an Event record:

```elixir
defmodule LiveMap.GeoJSON do
  defstruct type: "Feature",
            geometry: %{type: "LineString", coordinates: []},
            properties: %{ad1: "", ad2: "", date: Date.utc_today(), user: nil, distance: 0
            }

  defp set_coords(%LiveMap.GeoJSON{} = geojson, startpoint, endpoint) do
    put_in(geojson.geometry.coordinates, [startpoint, endpoint])
  end
  defp set_props(%LiveMap.GeoJSON{} = geojson,...)
  ...
end
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

You need to tell Esbuild that you use "png" images for the markers. In the config

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
@import 'leaflet/dist/leaflet.css';
@import 'leaflet-control-geocoder/dist/Control.Geocoder.css';

#mymap { height: 400px; width: 100%; }
```

To render the map, add two bindings: `phx-update="ignore"` to let Leaflet update tiles without interacting with LiveView (see [docs](https://hexdocs.pm/phoenix_live_view/dom-patching.html#content)), and `phx-hook` to your custom "hook":

```elixir
use Phoenix.LiveComponent
def render(assigns) do
  ~H"""
    <div id="mymap" phx-update="ignore" phx-hook="MapHook"></div>
  ""
end
``` 

Client-side, you name this object as in your `phx-hook`:

```js
export const MapHook = {
  import L from 'leaflet'

  mounted() {
    const map = L.('mymap', { renderer: L.canvas() }).setView(...) 
  }
}
```

and add this "hook" in "/assets/app.js" to the LiveSocket object:

```js
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: { MapHook },
});
```

[:arrow_up:]()

### Leaflet MapHook code