import L, { marker } from "leaflet";
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
    place.current = L.latLng(lat, lng);
    map.flyTo([lat, lng], 12);
  }
  function locationDenied() {
    window.alert("location access denied");
  }
}

const place = proxy({ coords: [], distance: 0, current: [] });
const eventsparams = proxy({ center: [], distance: 100_000 });

const newEvent = proxy({
  date: null,
  start_name: "",
  end_name: "",
  start_loc: [],
  end_loc: [],
  distance: 0,
});

export const MapHook = {
  mounted() {
    const map = L.map("map").setView([45, -1], 10);
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 20,
      attribution: "c OpenStreeMap",
    }).addTo(map);

    getLocation(map);

    // use pushEventTo with phx-target (elements)
    subscribe(place, () => {
      this.pushEventTo("1", "add_point", { place });
    });

    subscribe(newEvent, () => this.pushEventTo("1", "new_event", { newEvent }));

    subscribe(eventsparams, () => {
      this.pushEventTo("1", "postgis", { eventsparams });
    });

    const layergroup = L.layerGroup().addTo(map);
    const lineLayer = L.layerGroup().addTo(map);
    const geoCoder = L.Control.Geocoder.nominatim();

    function addButton(html = "") {
      return `<h5>${html}</h5>
      <button type="button" class="remove">Remove</button>`;
    }

    const coder = L.Control.geocoder({ defaultMarkGeocode: false }).addTo(map);

    coder.on("markgeocode", function ({ geocode: { center, html, name } }) {
      html = addButton(html);
      const marker = L.marker(center, { draggable: true });
      marker.addTo(layergroup).bindPopup(html);
      map.flyTo(center, 15);

      const location = {
        id: marker._leaflet_id,
        lat: center.lat,
        lng: center.lng,
        name,
        country,
      };

      if (place.coords.find((c) => c.id === location.id) === undefined)
        place.coords.push(location);

      marker.on("popupopen", () => maybeDelete(marker, location.id));
      marker.on("dragend", () => draggedMarker(marker, location.id, lineLayer));
    });

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

    map.on("click", function (e) {
      geoCoder.reverse(e.latlng, 12, (result) => {
        let {
          html,
          name,
          properties: {
            address: { country },
          },
        } = result[0];
        console.log(country);
        html = addButton(html);
        const marker = L.marker(e.latlng, { draggable: true });
        marker.addTo(layergroup).bindPopup(html);
        // you need to add to the map before getting the _leaflet_id
        const location = {
          id: marker._leaflet_id,
          lat: e.latlng.lat.toFixed(4),
          lng: e.latlng.lng.toFixed(4),
          name,
          country,
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
    });

    function discover(marker, newLatLng, index, id) {
      geoCoder.reverse(newLatLng, 12, (result) => {
        let {
          html,
          name,
          properties: {
            address: { country },
          },
        } = result[0];
        place.coords[index] = {
          name,
          country,
          id,
          lat: newLatLng.lat.toFixed(4),
          lng: newLatLng.lng.toFixed(4),
        };

        if (index <= 1) {
          lineLayer.clearLayers();
          drawLine();
        }

        html = addButton(html);
        return marker.bindPopup(html);
      });
    }

    function draggedMarker(mark, id, lineLayer) {
      const newLatLng = mark.getLatLng();
      mark.setLatLng(newLatLng);
      // layergroup.removeLayer(mark);
      // const marker = L.marker(newLatLng, { draggable: true });
      // marker.addTo(layergroup);
      const index = place.coords.findIndex((c) => c.id === id);
      discover(mark, newLatLng, index, id);

      mark.on("popupopen", () => maybeDelete(mark, id));
      mark.on("dragend", () => draggedMarker(mark, id, lineLayer));
    }

    function drawLine() {
      const [start, end, ...rest] = place.coords;
      if (start && end) {
        const p1 = L.latLng([start.lat, start.lng]);
        const p2 = L.latLng([end.lat, end.lng]);
        L.polyline(
          [
            [start.lat, start.lng],
            [end.lat, end.lng],
          ],
          {
            color: "red",
          }
        ).addTo(lineLayer);
        place.distance = (p1.distanceTo(p2) / 1_000).toFixed(2);

        newEvent.date = Date.now();
        newEvent.start_name = place.coords[0].name;
        newEvent.end_name = place.coords[1].name;
        newEvent.start_loc = [place.coords[0].lng, place.coords[0].lat];
        newEvent.end_loc = [place.coords[1].lng, place.coords[1].lat];
        newEvent.distance = place.distance;
        newEvent.country = place.coords[0].country;
      }
    }

    map.on("moveend", function () {
      eventsparams.center = map.getCenter();
      const { _northEast: ne, _southWest: sw } = map.getBounds();
      eventsparams.distance = map
        .distance(L.latLng(ne), L.latLng(sw))
        .toFixed(0);
    });

    this.handleEvent("add", ({ coords: [lat, lng] }) => {
      const coords = L.latLng([Number(lat), Number(lng)]);

      const index = place.coords.length;
      const marker = L.marker(coords, { draggable: true });
      marker.addTo(layergroup).bindPopup(addButton);

      // to get the id, you need to add to the layer firstly
      const id = marker._leaflet_id;
      console.log(id);
      discover(marker, coords, index, id);
      marker.on("popupopen", () => maybeDelete(marker, id));
      marker.on("dragend", () => draggedMarker(marker, id, lineLayer));
    });

    this.handleEvent("delete_marker", ({ id }) => {
      // remove marker found by id from the group of markers
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
