import { proxy, subscribe } from "valtio";
import { randomColor } from "randomcolor";

async function libLoader() {
  return Promise.all([
    import("leaflet"),
    import("leaflet-control-geocoder"),
    import("leaflet/dist/images/marker-shadow.png"),
    import("leaflet/dist/images/marker-icon.png"),
    import("./bucketLimiter.js"),
  ]);
}

// import takeToken from "./bucket";

const optionLong = { interval: 5_000, bucketCapacity: 1 };
const optionShort = { internval: 3_000, bucketCapacity: 1 };

const lineStyle = {
  color: "black",
  dashArray: "10, 10",
  dashOffset: 50,
  weight: 1,
};

const customOptions = {
  maxWidth: "175",
  width: "175",
  className: "popupCustom",
};

async function handleGeolocationPermission(map) {
  window.alert("Geolocate yourself!");
  return navigator.permissions
    .query({ name: "geolocation" })
    .then(({ state }) => {
      if (state === "granted" || state === "prompt") return getLocation(map);
    });
}

// call the geolocation API and redirect the map to te found location
function getLocation(map) {
  navigator.geolocation.getCurrentPosition(locationFound, locationDenied);
  function locationFound({ coords: { latitude: lat, longitude: lng } }) {
    map.setView([lat, lng], 11);
    // map.flyTo([lat, lng], 11);
  }
  function locationDenied() {
    window.alert("location access denied");
  }
}

function addButton(html = "") {
  return `
  <p>${html}</p>
  <p class="flex justify-center">
  <button type="button"
  class="remove inline-block px-6 py-2.5 bg-red-600 text-white font-medium text-xs leading-tight uppercase rounded-full shadow-md hover:bg-red-700 hover:shadow-lg focus:bg-red-700 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-red-800 active:shadow-lg transition duration-150 ease-in-out"
  ">Remove</button>
  </p>
  `;
}

// function setRandColor() {
//   return "#" + Math.floor(Math.random() * 16777215).toString(16);
// }

// proxied store of the event with markers data
const place = proxy({
  coords: [], // list of {leaflet_id, lat,lng, name} of markers where name is the address
  distance: 0, // distance between 2 markers
  color: "#0000",
});

// proxied centre and radius of the map
const movingmap = proxy({ center: [], distance: 10_000 });

export const MapHook = {
  destroyed() {
    cancel(this.el);
  },
  async mounted() {
    // load Leaflet and Geocoder async
    const [
      L,
      { geocoder },
      { default: icon },
      { default: iconShadow },
      { default: takeToken },
    ] = await libLoader();

    const start_spinner = () =>
      this.pushEventTo("#map", "mapoff", { id: "map" });

    const stop_spinner = () => this.pushEventTo("#map", "mapon", { id: "map" });

    if (L) stop_spinner();

    const DefaultIcon = L.icon({
      iconUrl: icon,
      shadowUrl: iconShadow,
      iconAnchor: [10, 10],
    });

    L.Marker.prototype.options.icon = DefaultIcon;

    const map = L.map("map", { renderer: L.canvas() }).setView([20, 10], 2);

    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 19,
      attribution: "c OpenStreeMap",
    }).addTo(map);

    // layer for the Event creation
    const layergp = L.layerGroup().addTo(map);
    //  layer for the Line for the Event creation
    const lineLayer = L.layerGroup().addTo(map);
    // layer for the fetched Events from the DB
    const datagroup = L.layerGroup().addTo(map);
    // layer for the highlighted
    const highlightLayer = L.layerGroup().addTo(map);

    //**** wrapper to Nominatim endpoint. limited to one request per second
    const geoCoder = L.Control.Geocoder.nominatim();

    // ***** ask to run the geolcation API.
    // delay spinner if gelocation is fast
    let timeoutIDGeoloc = undefined;

    async function geolocate(map) {
      document
        .getElementById("geolocation")
        .addEventListener("click", async () => {
          await handleGeolocationPermission(map);
          if (!timeoutIDGeoloc)
            timeoutIDGeoloc = setTimeout(() => {
              start_spinner();
            }, 200);
        });
    }
    geolocate(map);

    // *********** form Geocoder alternative
    // provides a form to find a place by its name and fly-to
    const coder = L.Control.geocoder({
      expand: "click",
      defaultMarkGeocode: false,
    }).addTo(map);

    coder.on("markgeocode", function ({ geocode: { center, html, name } }) {
      start_spinner();
      map.setView(center, 11);
      // map.flyTo(center, 11);
      stop_spinner();
    });

    // store of new event. use pushEventTo with phx-target (elements)
    subscribe(place, () => this.pushEventTo("#map", "add_point", { place }));

    //  ******** store the events
    let myEvts = [{ type: "featureCollection", features: [] }];
    // store the toggled = highlighted events from checkbox SSR
    let toggled = [];

    // "highlight" an event-id (DB) and put in highlighterLayer
    this.handleEvent("toggle_up", ({ id }) => {
      // we find the event with "id" and add it to the highlighted layer
      L.geoJSON(myEvts, {
        filter: function (feature, layer) {
          if (feature.properties.id === Number(id)) {
            toggled.push(feature);
            return { color: "#ff0000", weight: 8 };
          }
        },
      }).addTo(highlightLayer);
    });

    //  remove the "highlighted" layer by event-id (DB)
    this.handleEvent("toggle_down", ({ id }) => {
      // we remove everything <=> set back to "normal"
      highlightLayer.clearLayers();
      //  define a new set with event "id" removed
      toggled = toggled.filter((t) => t.properties.id !== Number(id));
      //  and put back a lighlighted layer on this new filtered set
      L.geoJSON(toggled, {
        onEachFeature: () => ({ color: "#ff0000", weight: 8 }),
      }).addTo(highlightLayer);
    });

    // remove the "highlighted" layer to keep in sync with checkboxes defaults false
    this.handleEvent("toggle_all_down", () => {
      highlightLayer.clearLayers();
      toggled = [];
    });

    // ****************
    // reset the layers & "place" storage
    function clearEvents() {
      layergp.clearLayers();
      lineLayer.clearLayers();
      datagroup.clearLayers();
      place.coords = [];
      place.distance = 0;
    }

    // remove event in case of error
    this.handleEvent("clear_event", () => clearEvents());

    this.handleEvent("delete_event", ({ id }) => {
      clearEvents();
      const [{ features: features = [] }] = myEvts;
      myEvts[0].features = features.filter(
        (feature) => feature.properties.id !== Number(id)
      );
      return handleData(myEvts);
    });

    // add a broadcasted new event
    this.handleEvent("new_pub", ({ geojson }) => {
      clearEvents();
      let feature = myEvts[0]?.features;
      feature === null ? (feature = [geojson]) : feature.push(geojson);
      myEvts[0].features = feature;
      return handleData(myEvts);
    });

    // received update from DB after moved map
    this.handleEvent("update_map", ({ data }) => handleData(data));

    function handleData(data) {
      console.log(Object.keys(datagroup._layers).length);
      datagroup.clearLayers();
      // save geojson to local store
      myEvts = data;
      clearTimeout(timeoutIDGeoloc);
      timeoutIDGeoloc = undefined;
      stop_spinner();
      // process to create line and markers on each feature
      if (data)
        return L.geoJSON(data, {
          style: lineStyle,
          onEachFeature: onEachFeature,
        }).addTo(datagroup);
    }

    function onEachFeature(feature, layer) {
      const { ad1, ad2, email, date, distance, color } = feature.properties;
      const [start, end] = layer.getLatLngs();
      setCircleMarker(start, ad1, email, date, distance, color);
      setCircleMarker(end, ad2, email, date, distance, color);
    }

    function setCircleMarker(pos, ad, owner, date, distance, color) {
      L.circleMarker(pos, { radius: 10, color: color })
        .bindPopup(info(ad, owner, date, distance), customOptions)
        .addTo(datagroup);
    }

    function info(ad, owner, date, distance) {
      const evtDate = new Date(date).toDateString();
      return `
            <h2 class="font-bold bg-sky-500/50" >${evtDate} </h2>
            <h5>${owner} </h5>
            <p class="text-xs truncate"> ${ad} </p>
            <h1 class="font-bold text-center"> ${distance} km</h1>
            `;
    }

    // ******** Primitives to deal with new event creation, drag, delete and get address

    // Delete: callback to "popupopen": you get a delete button defined above inside
    function maybeDelete(marker, id) {
      return document
        .querySelector("button.remove")
        .addEventListener("click", function () {
          place.coords = place.coords.filter((c) => c.id !== id) || [];
          layergp.removeLayer(marker);
          const index = place.coords.findIndex((c) => c.id === Number(id));
          if (index <= 1) {
            place.distance = 0;
            lineLayer.clearLayers();
          }
          if (place.coords.length >= 2) {
            drawLine();
          }
        });
    }

    // async fetch to get the address if any
    function discover(marker, newLatLng, index, id) {
      geoCoder.reverse(newLatLng, 12, (result) => {
        let { html, name } = result[0];
        place.coords[index] = {
          lat: newLatLng.lat.toFixed(4),
          lng: newLatLng.lng.toFixed(4),
          name,
          id,
        };
        // since we are in an async function, this has to be done here
        if (index <= 1) {
          lineLayer.clearLayers();
          drawLine();
        }

        html = addButton(html);
        return marker.bindPopup(html);
      });
    }

    // recursif Update callback to "dragend": fetches new address and redraws if needed
    async function draggedMarker(mark, id, lineLayer) {
      // limitation of 1 request per second for Nominatim
      mark?.dragging.disable();
      await takeToken("click", optionLong);
      mark.dragging.enable();

      const newLatLng = mark.getLatLng();
      mark.setLatLng(newLatLng);
      const index = place.coords.findIndex((c) => c.id === id);

      discover(mark, newLatLng, index, id);
      mark.on("popupopen", () => maybeDelete(mark, id));
      mark.on("dragend", async () => {
        await draggedMarker(mark, id, lineLayer);
      });
    }

    async function updateDeleteMarker(marker, id) {
      try {
        marker.on("popupopen", () => maybeDelete(marker, id));
        marker.dragging.disable();
        await takeToken("click", optionLong);
        marker.dragging.enable();
        marker.on("dragend", () => draggedMarker(marker, id, lineLayer));
      } catch (err) {
        return;
      }
    }

    // we run "drawLine" when the two first markers (= the event) are changed
    function drawLine() {
      const [start, end, ...rest] = place.coords;
      // if there are two markers, do...
      if (start && end) {
        // draw the line in red
        L.polyline(
          [
            [start.lat, start.lng],
            [end.lat, end.lng],
          ],
          { color: "red" }
        ).addTo(lineLayer);
        // calculate the line length
        const p1 = L.latLng([start.lat, start.lng]);
        const p2 = L.latLng([end.lat, end.lng]);
        place.distance = (p1.distanceTo(p2) / 1_000).toFixed(1);
        place.color = randomColor();
      }
    }

    // Create listener: returns a marker with an address
    map.on("click", create);
    async function create(e) {
      // fetch the address from the endpoint "nominatim"
      // limitation of 1 request per second for Nominatim
      await takeToken("click", optionShort);

      return geoCoder.reverse(e.latlng, 12, (result) => {
        if (!result[0]) return;
        let { html, name } = result[0];
        if (html) html = addButton(html);

        const marker = L.marker(e.latlng, { draggable: true });
        // const marker = L.marker(e.latlng);
        marker.addTo(layergp).bindPopup(html);
        // you need to add the marker to the map to get the _leaflet_id
        const location = {
          id: marker._leaflet_id,
          lat: e.latlng.lat.toFixed(4),
          lng: e.latlng.lng.toFixed(4),
          name,
        };

        if (place.coords.find((c) => c.id === location.id) === undefined) {
          place.coords.push(location);
          drawLine();
        }
        return updateDeleteMarker(marker, location.id);
      });
    }

    // html = addButton(html);
    // const marker = L.marker(center, { draggable: true });
    // marker.addTo(layergp).bindPopup(html);

    // const location = {
    //   id: marker._leaflet_id,
    //   lat: center.lat,
    //   lng: center.lng,
    //   name,
    // };
    // if (place.coords.find((c) => c.id === location.id) === undefined)
    //   place.coords.push(location);
    // updateDeleteMarker(marker, location.id);
    // });

    // ****** capture map moves
    // moveend mutates "movingmap" push to backend
    subscribe(movingmap, () => {
      this.pushEventTo("#map", "postgis", { movingmap });
    });

    // listener that mutates "movingmap" object with new coords map for the backend to retrieve events
    map.on("moveend", () => {
      movingmap.center = map.getCenter();
      const { _northEast: ne, _southWest: sw } = map.getBounds();
      movingmap.distance = Number(
        map.distance(L.latLng(ne), L.latLng(sw)) / 2
      ).toFixed(1);
    });

    // ***** Delete listener triggered from SSR pushEvent
    this.handleEvent("delete_marker", ({ id }) => {
      layergp.eachLayer((layer) => {
        if (layer._leaflet_id === Number(id)) layer.removeFrom(layergp);
      });
      // udpate the state and redraw the line if necessary
      const index = place.coords.findIndex((c) => c.id === Number(id));
      place.coords = place.coords.filter((c) => c.id !== Number(id)) || [];
      if (index <= 1) {
        lineLayer.clearLayers();
        place.distance = 0;
      }
      if (place.coords.length >= 2) {
        drawLine();
      }
    });
  },
};
