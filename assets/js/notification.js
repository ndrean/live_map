function sendNotification(to, from, receiver) {
  const notification = new Notification("New message:", {
    icon: "https://cdn-icons-png.flaticon.com/512/733/733585.png",
    body: `@${to}: from ${from}`,
  });
  setTimeout(() => {
    notification.close();
  }, 5_000);
}

const showError = () => window.alert("Notifications are blocked");

export const Notify = {
  mounted() {
    console.log("Notify mounted");

    // don't ask user for notification permission on mount but only if one pushes this first notification
    this.handleEvent("notify", ({ to, from, receiver }) => {
      if (!("Notification" in window)) return showError();

      (async () => {
        await Notification.requestPermission((permission) => {
          return permission === "granted"
            ? sendNotification(to, from, receiver)
            : showError();
        });
      })();
    });
  },
};
