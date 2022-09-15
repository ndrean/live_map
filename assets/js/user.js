import { Socket, Presence } from "phoenix";

const socket = new Socket("/socket", {
  params: { token: sessionStorage.userToken },
});

socket.connect();

channel
  .join()
  .receive("ok", (resp) => {
    console.log("Joined successfully", resp);
    document.addEventListener("mousemove", (e) => {
      const x = e.pageX / window.innerWidth;
      const y = e.pageY / window.innerHeight;
      console.log(x, y);
    });
    // remove the code that updates cursor positions on the move event
  })
  .receive("error", (resp) => {
    console.log("Unable to join", resp);
  });

const presence = new Presence(channel);
presence.onSync((res) => {
  console.log(res);
});
