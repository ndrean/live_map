// We import the CSS which is extracted to its own file by esbuild. Remove this line if you add a your own CSS build pipeline (e.g postcss).
// import "../css/app.css";

// import "./user_socket.js";

// The simplest option is to put them in assets/vendor and import them using relative paths:
//     import "../vendor/some-package.js"
// Alternatively, you can `npm install some-package --prefix assets` and import them using a path starting with the package name:
//     import "some-package"

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { clsx } from "clsx";
import topbar from "../vendor/topbar";
import { MapHook } from "./maphook";
import { infiniteScroll } from "./infiniteScroll";

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: { MapHook, infiniteScroll, joinCall },
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (info) => topbar.show());
window.addEventListener("phx:page-loading-stop", (info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
liveSocket.enableDebug();
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

//  clear checkboxes if any checked in the table query events
window.addEventListener("phx:clear_boxes", () => {
  const table = document.getElementById("selected");
  if (table) {
    table
      .querySelectorAll('input[type="checkbox"]')
      .forEach((cb) => (cb.checked = false));
  }
});

// window.addEventListener("phx:toggle_class", ({ detail: { id } }) => {
//   const target = `button[phx-value-id="${id}"]`;
//   const button = document.querySelector(target);
//   button.disabled = true;
//   button.classList.contains("opacity-50")
//     ? button.classList.remove("opacity-50")
//     : button.classList.add("opacity-50");
// });

const joinCall = {
  mounted() {
    console.log("videos");
    initStream();
  },
};

let localStream = null;

async function initStream() {
  try {
    // Gets our local media from the browser and stores it as a const, stream.
    const stream = await navigator.mediaDevices.getUserMedia({
      audio: true,
      video: true,
      width: "1280",
    });
    // Stores our stream in the global constant, localStream.
    localStream = stream;
    // Sets our local video element to stream from the user's webcam (stream).
    document.getElementById("local-video").srcObject = stream;
  } catch (e) {
    console.log(e);
  }
}
