/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        // Mirrors the app's "horizon" palette (lib/theme/palettes.dart)
        brand: {
          DEFAULT: '#0F766E',
          dark: '#0C5D57',
          accent: '#F97362',
          cyan: '#0891B2',
        },
      },
    },
  },
  plugins: [],
}
