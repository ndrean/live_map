// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

let plugin = require("tailwindcss/plugin");

module.exports = {
  content: ["./js/**/*.js", "../lib/*_web.ex", "../lib/*_web/**/*.*ex"],
  theme: {
    extend: {
      colors: {
        "beige-1": "#AA803A",
        "beige-2": "#3A64AA",
        "google-blue": "#4285F4",
        "github-dark": "#24292e",
        "main-color-1": "#AA803A",
        "main-color-2": "#3A64AA",
        "yellow-1": {
          100: "#F2E9D9",
          200: "#E5D2B3",
          300: "#D8BC8D",
          400: "#CBA667",
          500: "#BE8F41",
          600: "#AA803A",
          700: "#725627",
          800: "#4C391A",
          900: "#261D0D",
        },
        "blue-2": {
          100: "#D9E2F2",
          200: "#B3C6E5",
          300: "#8DA9D8",
          400: "#678CCB",
          500: "#4170BE",
          600: "#3A64AA",
          700: "#274372",
          800: "#1A2D4C",
          900: "#0D1626",
        },
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("daisyui"),
    plugin(({ addVariant }) =>
      addVariant("phx-no-feedback", ["&.phx-no-feedback", ".phx-no-feedback &"])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-click-loading", [
        "&.phx-click-loading",
        ".phx-click-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-submit-loading", [
        "&.phx-submit-loading",
        ".phx-submit-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-change-loading", [
        "&.phx-change-loading",
        ".phx-change-loading &",
      ])
    ),
  ],
};
