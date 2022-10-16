export const fbLoginHook = {
  mounted() {
    const fbutton = document.getElementById("fbhook");
    if (fbutton) {
      (function (d, s, id) {
        var js,
          fjs = d.getElementsByTagName(s)[0];
        if (d.getElementById(id)) {
          return;
        }
        js = d.createElement(s);
        js.id = id;
        js.src = "https://connect.facebook.net/en_US/sdk.js";
        fjs.parentNode.insertBefore(js, fjs);
      })(document, "script", "facebook-jssdk");

      fbutton.addEventListener("click", () => {
        console.log("click");
        window.fbAsyncInit = function () {
          FB.init({
            appId: 366589421180047,
            cookie: true,
            xfbml: true,
            version: "v15.0",
          });
          FB.AppEvents.logPageView();
          FB.getLoginStatus(function (response) {
            // Called after the JS SDK has been initialized.
            console.log({ response }, "loginStatus2");
            statusChangeCallback(response); // Returns the login status.
          });
          FB.login(
            function (response) {
              if (response.status === "connected") {
                // Logged into your webpage and Facebook.
              } else {
                // The person is not logged into your webpage or we are unable to tell.
              }
            },
            { scope: "public_profile,email" }
          );
          checkLoginState();
          FB.login()();
        };

        function checkLoginState() {
          // Called when a person is finished with the Login Button.
          FB.getLoginStatus(function (response) {
            console.log({ response }, "getLoginStatus");
            // See the onlogin handler
            statusChangeCallback(response);
          });
        }

        function statusChangeCallback(response) {
          // Called with the results from FB.getLoginStatus().
          console.log("statusChangeCallback2");
          console.log(response); // The current login status of the person.
          if (response.status === "connected") {
            // Logged into your webpage and Facebook.
            testAPI();
          } else {
            // Not logged into your webpage or we are unable to tell.
            document.getElementById("status").innerHTML =
              "Please log " + "into this webpage.";
          }
        }
      });
    }
  },
};
