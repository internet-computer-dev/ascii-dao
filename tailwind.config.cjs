/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./frontend/**/*.{html,js,svelte,ts}'],
  theme: {
    extend: {},
  },
  daisyui: {
    themes: ["lofi"],
  },
  plugins: [require("daisyui")],
}
