export const fbLoginHook = {
  mounted() {
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

    window.fbAsyncInit = function () {
      FB.init({
        appId: 366589421180047,
        cookie: true,
        xfbml: true,
        version: "v15.0",
      });

      FB.getLoginStatus(function (response) {
        console.log({ response }, "loginStatus");
        // Called after the JS SDK has been initialized.
        statusChangeCallback(response); // Returns the login status.
      });

      //   FB.AppEvents.logPageView();
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
    };

    function statusChangeCallback(response) {
      // Called with the results from FB.getLoginStatus().
      console.log({ response }, "statusChangeCallback"); // The current login status of the person.
      if (response.status === "connected") {
        // Logged into your webpage and Facebook.
        console.log("connected");
      } else {
        // Not logged into your webpage or we are unable to tell.
        document.getElementById("status").innerHTML =
          "Please log " + "into this webpage.";
      }
    }
  },
};
