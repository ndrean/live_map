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

export const MapHook = {
  mounted() {
    const map = L.map("map").setView([45, -1.5], 10);
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 20,
      attribution: "c OpenStreeMap",
    }).addTo(map);

    getLocation(map);
    subscribe(place, () => this.pushEvent("add_point", { place }));

    const layerGroup = L.layerGroup().addTo(map);
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
      marker.addTo(layerGroup).bindPopup(html);
      map.flyTo(center, 15);

      const location = {
        id: marker._leaflet_id,
        lat: center.lat,
        lng: center.lng,
        name,
      };

      if (place.coords.find((c) => c.id === location.id) === undefined)
        place.coords.push(location);

      marker.on("popupopen", () => openMarker(marker, location.id));
      marker.on("dragend", () => draggedMarker(marker, location.id, lineLayer));
    });

    map.on("moveend", function () {
      console.log(map.getBounds());
    });

    function openMarker(marker, id) {
      document
        .querySelector("button.remove")
        .addEventListener("click", function () {
          place.coords = place.coords.filter((c) => c.id !== id) || [];
          layerGroup.removeLayer(marker);
          const index = place.coords.findIndex((c) => c.id === id);
          if (index <= 1) lineLayer.clearLayers();
          place.distance = 0;
          if (place.coords.length >= 2) {
            drawLine();
          }
        });
    }

    map.on("click", function (e) {
      geoCoder.reverse(e.latlng, 12, (result) => {
        let { html, name } = result[0];
        html = addButton(html);
        const marker = L.marker(e.latlng, { draggable: true });
        marker.addTo(layerGroup).bindPopup(html);

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
        marker.on("popupopen", () => openMarker(marker, location.id));
        marker.on("dragend", () =>
          draggedMarker(marker, location.id, lineLayer)
        );
      });
    });

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
      }
    }

    function discover(marker, newLatLng, index, id) {
      geoCoder.reverse(newLatLng, 12, (result) => {
        let { html, name } = result[0];
        place.coords[index] = {
          name,
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
      layerGroup.removeLayer(mark);
      const marker = L.marker(newLatLng, { draggable: true });
      marker.addTo(layerGroup);
      const index = place.coords.findIndex((c) => c.id === id);
      discover(marker, newLatLng, index, id);

      marker.on("popupopen", () => openMarker(marker, id));
      marker.on("dragend", () => draggedMarker(marker, id, lineLayer));
    }

    this.handleEvent("add", ({ coords: [lat, lng] }) => {
      const coords = L.latLng([Number(lat), Number(lng)]);
      const marker = L.marker(coords);
      marker.addTo(layerGroup).bindPopup(addButton);
      marker.on("popupopen", () => openMarker(marker, marker._leaflet_id));
    });
  },
};
