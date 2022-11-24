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
// import topbar from "../vendor/topbar";
import { ChartHook } from "./charthook";
import { Notify } from "./notification";
// import { Facebook } from "./facebook";
const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: { ChartHook, Notify },
});

// liveSocket = new LiveSocket("/chat", Socket, {
//   params: { _csrf_token: csrfToken },
//   // hooks: { MapHook },
// });

// Show progress bar on live navigation and form submits
// topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
// window.addEventListener("phx:page-loading-start", (info) => topbar.show());
// window.addEventListener("phx:page-loading-stop", (info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// liveSocket.enableDebug();
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

//  clear checkboxes if any checked in the table query events after sending new event
window.addEventListener("phx:clear_boxes", () => {
  const table = document.getElementById("selected");
  if (table) {
    table
      .querySelectorAll('input[type="checkbox"]')
      .forEach((cb) => (cb.checked = false));
  }
});

//  FB-SDK
const fbutton = document.getElementById("fbhook");
if (fbutton) Facebook(fbutton);

// GOOGLE-ONE-TAP
const oneTap = document.querySelector("#g_id_onload");
if (oneTap)
  oneTap.dataset.login_uri = window.location.href + "auth/google/callback";

function sendNotification(to, from, receiver) {
  console.log("here", to, from, receiver, window.userId);
  if (receiver === window.userId) {
    const notification = new Notification("New message:", {
      icon: "https://cdn-icons-png.flaticon.com/512/733/733585.png",
      body: `@${to}: from ${from}`,
    });
    setTimeout(() => {
      notification.close();
    }, 5_000);
  }
}

window.addEventListener("phx:notify", ({ detail: { to, from, receiver } }) => {
  (async () => {
    await Notification.requestPermission((permission) => {
      console.log("notification");
      return permission === "granted"
        ? sendNotification(to, from, receiver)
        : showError();
    });
  })();
});
