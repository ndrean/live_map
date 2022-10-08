import L from "leaflet";
import { geocoder } from "leaflet-control-geocoder";
import iconShadow from "leaflet/dist/images/marker-shadow.png";
import icon from "leaflet/dist/images/marker-icon.png";
import { proxy, subscribe } from "valtio";
import { randomColor } from "randomcolor";

const DefaultIcon = L.icon({
  iconUrl: icon,
  shadowUrl: iconShadow,
  iconAnchor: [10, 10],
});

L.Marker.prototype.options.icon = DefaultIcon;

const lineStyle = {
  color: "black",
  dashArray: "10, 10",
  dashOffset: 50,
  weight: 1,
};

// call the geolocation API and redirect the map to te found location
function getLocation(map) {
  navigator.geolocation.getCurrentPosition(locationFound, locationDenied);
  function locationFound({ coords: { latitude: lat, longitude: lng } }) {
    map.flyTo([lat, lng], 11);
  }
  function locationDenied() {
    window.alert("location access denied");
  }
}

function addButton(html = "") {
  return `
  <h5>${html}</h5>
  <button type="button"
  class="remove inline-block px-6 py-2.5 bg-red-600 text-white font-medium text-xs leading-tight uppercase rounded-full shadow-md hover:bg-red-700 hover:shadow-lg focus:bg-red-700 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-red-800 active:shadow-lg transition duration-150 ease-in-out"
  ">Remove</button>
  `;
}

function setRandColor() {
  return "#" + Math.floor(Math.random() * 16777215).toString(16);
}

// proxied store of the event with markers data
const place = proxy({
  coords: [], // list of {leaflet_id, lat,lng, name} of markers where name is the address
  distance: 0, // distance between 2 markers
  color: randomColor(),
});

// proxied centre and radius of the map
const movingmap = proxy({ center: [], distance: 10_000 });

export const MapHook = {
  mounted() {
    const map = L.map("map", { renderer: L.canvas() }).setView([45, -1], 10);
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 19,
      attribution: "c OpenStreeMap",
    }).addTo(map);

    const layergroup = L.layerGroup().addTo(map);
    const datagroup = L.layerGroup().addTo(map);
    const lineLayer = L.layerGroup().addTo(map);
    const showLayer = L.layerGroup().addTo(map);

    // limited to one request per second
    const geoCoder = L.Control.Geocoder.nominatim();
    let mymarkers = null;
    // run the geolcation API.
    // Alternatively, the "coder" is provided circa L232
    getLocation(map);

    // use pushEventTo with phx-target (elements)
    subscribe(place, () => this.pushEventTo("1", "add_point", { place }));

    // moveend mutates "movingmap"
    subscribe(movingmap, () =>
      this.pushEventTo("#map", "postgis", { movingmap })
    );

    this.handleEvent("new pub", ({ geojson }) => {
      clearEvent();
      handleData(geojson);
    });

    // reset the newly saved event
    function clearEvent() {
      layergroup.clearLayers();
      lineLayer.clearLayers();
      place.coords = [];
      place.distance = 0;
    }

    let toggled = [];

    // find (by the db id) and highlight the path
    this.handleEvent("toggle_up", ({ id }) => {
      L.geoJSON(mymarkers, {
        filter: function (feature, layer) {
          if (feature.properties.id === Number(id)) {
            toggled.push(feature);
            return { color: "#ff0000", weight: 8 };
          }
        },
      }).addTo(showLayer);
    });

    //  remove the highlight layer
    this.handleEvent("toggle_down", ({ id }) => {
      showLayer.clearLayers();
      toggled = toggled.filter((t) => t.properties.id !== Number(id));
      L.geoJSON(toggled, {
        filter: function (feature, layer) {
          return { color: "#ff0000", weight: 8 };
        },
      }).addTo(showLayer);
    });

    // listener to update existing events at location
    this.handleEvent("update_map", ({ data }) => handleData(data));

    function handleData(data) {
      // save geojson to be able to highlight a specific event
      mymarkers = data;
      // process to create line and markers on each feature
      if (data)
        L.geoJSON(data, {
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
        .bindPopup(info(ad, owner, date, distance))
        .addTo(datagroup);
    }

    function info(ad, owner, date, distance) {
      const evtDate = new Date(date).toDateString();
      return `
            <h4>${owner}, the ${evtDate}</h4>
            <h6>${ad}</h6>
            <h1>${distance} km</h1>
            `;
    }

    // Delete: callback to "popupopen": you get a delete button defined above inside
    function maybeDelete(marker, id) {
      document
        .querySelector("button.remove")
        .addEventListener("click", function () {
          place.coords = place.coords.filter((c) => c.id !== id) || [];
          layergroup.removeLayer(marker);
          const index = place.coords.findIndex((c) => c.id === Number(id));
          if (index <= 1) {
            lineLayer.clearLayers();
            place.distance = 0;
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
    function draggedMarker(mark, id, lineLayer) {
      const newLatLng = mark.getLatLng();
      mark.setLatLng(newLatLng);
      const index = place.coords.findIndex((c) => c.id === id);
      // limitation of 1 request per second for Nominatim

      setTimeout(() => {
        discover(mark, newLatLng, index, id);
      }, 1000);
      mark.on("popupopen", () => maybeDelete(mark, id));
      mark.on("dragend", () => draggedMarker(mark, id, lineLayer));
    }

    function updateDeleteMarker(marker, id) {
      marker.on("popupopen", () => maybeDelete(marker, id));
      marker.on("dragend", () => draggedMarker(marker, id, lineLayer));
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
    function create(e) {
      // fetch the address from the endpoint "nominatim"
      geoCoder.reverse(e.latlng, 12, (result) => {
        if (!result[0]) return;
        let { html, name } = result[0];
        if (html) html = addButton(html);

        const marker = L.marker(e.latlng, { draggable: true });
        marker.addTo(layergroup).bindPopup(html);
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
        updateDeleteMarker(marker, location.id);
      });
    }

    // provides a form to find a place by its name and fly-to
    const coder = L.Control.geocoder({ defaultMarkGeocode: false }).addTo(map);
    //
    coder.on("markgeocode", function ({ geocode: { center, html, name } }) {
      map.flyTo(center, 10);
      html = addButton(html);
      const marker = L.marker(center, { draggable: true });
      marker.addTo(layergroup).bindPopup(html);

      const location = {
        id: marker._leaflet_id,
        lat: center.lat,
        lng: center.lng,
        name,
      };
      if (place.coords.find((c) => c.id === location.id) === undefined)
        place.coords.push(location);
      updateDeleteMarker(marker, location.id);
    });

    // listener that sends centre and radius of displayed map for the backend to retrieve events
    map.on("moveend", () => {
      movingmap.center = map.getCenter();
      const { _northEast: ne, _southWest: sw } = map.getBounds();
      movingmap.distance = Number(
        map.distance(L.latLng(ne), L.latLng(sw)) / 2
      ).toFixed(1);
    });

    // this.handleEvent("add", ({ coords: [lat, lng] }) => {
    //   const coords = L.latLng([Number(lat), Number(lng)]);
    //   const index = place.coords.length;
    //   const marker = L.marker(coords, { draggable: true });
    //   marker.addTo(layergroup).bindPopup(addButton);
    //   // to get the id, you need to add to the layer firstly
    //   const id = marker._leaflet_id;
    //   discover(marker, coords, index, id);
    //   updateDeleteMarker(marker, id);
    // });

    // Delete listener triggered from pushEvent
    this.handleEvent("delete_marker", ({ id }) => {
      layergroup.eachLayer((layer) => {
        if (layer._leaflet_id === Number(id)) layer.removeFrom(layergroup);
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
