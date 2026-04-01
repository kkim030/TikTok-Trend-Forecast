/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        pink: {
          light:   '#FFF0F3',
          DEFAULT: '#FFB6C1',
          medium:  '#F9A8B5',
          dark:    '#E91E8C',
          darker:  '#C2185B',
        },
      },
      fontFamily: {
        sans: ['Inter', 'ui-sans-serif', 'system-ui'],
      },
    },
  },
  plugins: [],
}
