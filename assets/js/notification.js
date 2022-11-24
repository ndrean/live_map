function sendNotification(to, from, receiver) {
  console.log("here", to, from, receiver, window.userId);
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
          console.log("notification");
          return permission === "granted"
            ? sendNotification(to, from, receiver)
            : showError();
        });
      })();

      //   (async function askPermission() {
      //     return new Promise(function (resolve, reject) {
      //       const permissionResult = Notification.requestPermission(function (
      //         result
      //       ) {
      //         resolve(result);
      //       });

      //       if (permissionResult) {
      //         permissionResult.then(resolve, reject);
      //       }
      //     }).then(function (permissionResult) {
      //       console.log(permissionResult);
      //       if (permissionResult !== "granted") {
      //         throw new Error("We weren't granted permission.");
      //       } else {
      //         sendNotification(to, from);
      //       }
      //     });
      //   })();
    });
  },
};
