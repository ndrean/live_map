// import Datepicker from "flowbite-datepicker/Datepicker";
import Datepicker from "@themesberg/tailwind-datepicker/Datepicker";

export const DateHook = {
  mounted() {
    const datepickerEl = document.getElementById("datepickerId");
    new Datepicker(datepickerEl, {
      // options
    });
  },
};
