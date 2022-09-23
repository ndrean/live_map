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
    map.flyTo([lat, lng], 11);
  }
  function locationDenied() {
    window.alert("location access denied");
  }
}

function addButton(html = "") {
  return `<h5>${html}</h5>
  <button type="button" class="remove">Remove</button>`;
}

function setRandColor() {
  return "#" + Math.floor(Math.random() * 16777215).toString(16);
}

// local proxied data stores where we subscribe to
const place = proxy({ coords: [], distance: 0, current: [] });
const movingmap = proxy({ center: [], distance: 100_000 });

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
    const map = L.map("map", { renderer: L.canvas() }).setView([45, -1], 10);
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 20,
      attribution: "c OpenStreeMap",
    }).addTo(map);

    // plugin "Leaflet Draw"
    // const drawnItems = L.geoJSON().addTo(map);

    // map.addControl(
    //   new L.Control.Draw({
    //     edit: {
    //       featureGroup: drawnItems,
    //     },
    //   })
    // );

    getLocation(map);

    // use pushEventTo with phx-target (elements)
    subscribe(place, () => {
      this.pushEventTo("1", "add_point", { place });
    });

    subscribe(newEvent, () =>
      this.pushEventTo("#map", "new_event", { newEvent })
    );

    // const throttled = (delay, fn) => {
    //   let lastCall = 0;
    //   return function (...args) {
    //     const now = new Date().getTime();
    //     if (now - lastCall < delay) {
    //       return;
    //     }
    //     console.log(now);
    //     lastCall = now;
    //     return fn(...args);
    //   };
    // };

    subscribe(movingmap, () => {
      this.pushEventTo("#map", "postgis", { movingmap });
    });

    const layergroup = L.layerGroup().addTo(map);
    const datagroup = L.layerGroup().addTo(map);
    const lineLayer = L.layerGroup().addTo(map);

    const geoCoder = L.Control.Geocoder.nominatim();

    // const throttle = (fn, milliseconds) => {
    //   let inThrottle;
    //   return function () {
    //     const args = arguments;
    //     const context = this;
    //     if (!inThrottle) {
    //       fn.apply(context, args);
    //       inThrottle = true;
    //       setTimeout(() => (inThrottle = false), milliseconds);
    //     }
    //   };
    // };
    // throttled listener to the backend sending features to populate the map

    this.handleEvent("update_map", ({ data }) => handleData(data));

    function handleData(data) {
      console.log("handelData");
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
      const { ad1, ad2, owner, date } = feature.properties;
      const [start, end] = layer.getLatLngs();
      const color = setRandColor();
      setCircleMarker(start, ad1, owner, date, color);
      setCircleMarker(end, ad2, owner, date, color);
    }

    function setCircleMarker(pos, ad, owner, date, color) {
      return L.circleMarker(pos, { radius: 10, color: color })
        .bindPopup(info(ad, owner, date))
        .addTo(datagroup);
    }

    function info(ad, owner, date) {
      const evtDate = new Date(date).toDateString();
      return `
            <h4>${owner}, the ${evtDate}</h4>
            <h5>${ad}</h5>
            `;
    }

    // this.handleEvent("init", ({ data }) => handleData(data));

    // provides a form to find a place by its name and fly-to
    const coder = L.Control.geocoder({ defaultMarkGeocode: false }).addTo(map);

    coder.on("markgeocode", function ({ geocode: { center, html, name } }) {
      //   html = addButton(html);
      //   const marker = L.marker(center, { draggable: true });
      //   marker.addTo(layergroup).bindPopup(html);
      map.flyTo(center, 10);

      //   const location = {
      //     id: marker._leaflet_id,
      //     lat: center.lat,
      //     lng: center.lng,
      //     name,
      //     country,
      //   };
      //   if (place.coords.find((c) => c.id === location.id) === undefined)
      //     place.coords.push(location);
      //   marker.on("popupopen", () => maybeDelete(marker, location.id));
      //   marker.on("dragend", () => draggedMarker(marker, location.id, lineLayer));
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
        let {
          html,
          name,
          properties: {
            address: { country },
          },
        } = result[0];
        if (html) html = addButton(html);

        console.log(result[0]);

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
    }

    // async fetch to get the address if any
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
        place.distance = (p1.distanceTo(p2) / 1_000).toFixed(2);
        // mutate the "newEvent" proxied object
        newEvent.date = Date.now();
        newEvent.start_name = place.coords[0].name;
        newEvent.end_name = place.coords[1].name;
        newEvent.start_loc = [place.coords[0].lng, place.coords[0].lat];
        newEvent.end_loc = [place.coords[1].lng, place.coords[1].lat];
        newEvent.distance = place.distance;
        newEvent.country = place.coords[0].country;
      }
    }

    map.on("moveend", updateMapBounds);

    // callback that sends coordinates and radius to the backend to populate the map
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
      console.log(id);
      discover(marker, coords, index, id);
      marker.on("popupopen", () => maybeDelete(marker, id));
      marker.on("dragend", () => draggedMarker(marker, id, lineLayer));
    });

    // Delete listener triggered from an action button in the table
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
