// We import the CSS which is extracted to its own file by esbuild. Remove this line if you add a your own CSS build pipeline (e.g postcss).
// import "../css/app.css";

// import "./user_socket.js"; <-- testing channels

// The simplest option is to put them in assets/vendor and import them using relative paths:
//     import "../vendor/some-package.js"
// Alternatively, you can `npm install some-package --prefix assets` and import them using a path starting with the package name:
//     import "some-package"

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";
import { ChartHook } from "./charthook";
import { Notify } from "./notification";
// import { Facebook } from "./facebook";
const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: { ChartHook, Notify, transition },
});

// liveSocket = new LiveSocket("/chat", Socket, {
//   params: { _csrf_token: csrfToken },
//   // hooks: { MapHook },
// });

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (info) => topbar.show());
window.addEventListener("phx:page-loading-stop", (info) => topbar.hide());

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

const transition = {
  mounted() {
    this.from = this.el.getAttribute("data-transition-from").split(" ");
    this.to = this.el.getAttribute("data-transition-to").split(" ");
    this.el.classList.add(...this.from);

    setTimeout(() => {
      this.el.classList.remove(...this.from);
      this.el.classList.add(...this.to);
    }, 10);
  },
  updated() {
    this.el.classList.remove("transition");
    this.el.classList.remove(...this.from);
  },
};
