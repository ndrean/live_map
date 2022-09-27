import L from "leaflet";
import { geocoder } from "leaflet-control-geocoder";
import iconShadow from "leaflet/dist/images/marker-shadow.png";
import icon from "leaflet/dist/images/marker-icon.png";
import { proxy, subscribe } from "valtio";

const DefaultIcon = L.icon({
  iconUrl: icon,
  shadowUrl: iconShadow,
  iconAnchor: [10, 10],
});

L.Marker.prototype.options.icon = DefaultIcon;

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

// local proxied data stores where we subscribe to
const place = proxy({
  coords: [],
  distance: 0,
  color: setRandColor(),
});
const movingmap = proxy({ center: [], distance: 100_000 });

export const MapHook = {
  mounted() {
    const map = L.map("map", { renderer: L.canvas() }).setView([45, -1], 10);
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 20,
      attribution: "c OpenStreeMap",
    }).addTo(map);

    const layergroup = L.layerGroup().addTo(map);
    const datagroup = L.layerGroup().addTo(map);
    const lineLayer = L.layerGroup().addTo(map);
    const geoCoder = L.Control.Geocoder.nominatim();

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

    // clear the saved event
    function clearEvent() {
      layergroup.clearLayers();
      lineLayer.clearLayers();
      place.coords = [];
      place.distance = 0;
    }

    // listener to update existing events at location
    this.handleEvent("update_map", ({ data }) => handleData(data));

    function handleData(data) {
      if (data) {
        L.geoJSON(data, {
          color: "black",
          dashArray: "20, 20",
          dashOffset: "20",
          weight: "2",
          onEachFeature: onEachFeature,
        }).addTo(map);
      }
    }

    function onEachFeature(feature, layer) {
      console.log("each feature ********");
      const { ad1, ad2, email, date, distance, color } = feature.properties;
      const [start, end] = layer.getLatLngs();
      setCircleMarker(start, ad1, email, date, distance, color);
      setCircleMarker(end, ad2, email, date, distance, color);
    }

    function setCircleMarker(pos, ad, owner, date, distance, color) {
      return L.circleMarker(pos, { radius: 10, color: color })
        .bindPopup(info(ad, owner, date, distance))
        .addTo(datagroup);
    }

    function info(ad, owner, date, distance) {
      const evtDate = new Date(date).toDateString();
      return `
            <h4>${owner}, the ${evtDate}</h4>
            <h5>${ad}</h5>
            <h5>${distance}</h5>
            `;
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
      marker.on("popupopen", () => maybeDelete(marker, location.id));
      marker.on("dragend", () => draggedMarker(marker, location.id, lineLayer));
    });

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
        // you need to add to the map before getting the _leaflet_id
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
        marker.on("popupopen", () => maybeDelete(marker, location.id));
        marker.on("dragend", () =>
          draggedMarker(marker, location.id, lineLayer)
        );
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

    // Update callback to "dragend": fetches new address and redraws if needed
    function draggedMarker(mark, id, lineLayer) {
      const newLatLng = mark.getLatLng();
      mark.setLatLng(newLatLng);
      const index = place.coords.findIndex((c) => c.id === id);
      discover(mark, newLatLng, index, id);

      mark.on("popupopen", () => maybeDelete(mark, id));
      mark.on("dragend", () => draggedMarker(mark, id, lineLayer));
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
        place.color = setRandColor();
      }
    }

    // listener that sends centre and radius of displayed map for the backend to retrieve events
    map.on("moveend", updateMapBounds);

    function updateMapBounds() {
      movingmap.center = map.getCenter();
      const { _northEast: ne, _southWest: sw } = map.getBounds();
      movingmap.distance = map.distance(L.latLng(ne), L.latLng(sw)).toFixed(1);
    }

    this.handleEvent("add", ({ coords: [lat, lng] }) => {
      const coords = L.latLng([Number(lat), Number(lng)]);

      const index = place.coords.length;
      const marker = L.marker(coords, { draggable: true });
      marker.addTo(layergroup).bindPopup(addButton);
      // to get the id, you need to add to the layer firstly
      const id = marker._leaflet_id;
      discover(marker, coords, index, id);
      marker.on("popupopen", () => maybeDelete(marker, id));
      marker.on("dragend", () => draggedMarker(marker, id, lineLayer));
    });

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
