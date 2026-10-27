/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: ['class', '[data-theme="midnight"]'],
  theme: {
    extend: {
      fontFamily: {
        serif: ['"EB Garamond"', 'Georgia', 'serif'],
        sans: ['-apple-system', 'BlinkMacSystemFont', '"SF Pro Display"', 'system-ui', 'sans-serif'],
      },
      colors: {
        scaffold: {
          light: '#F8F9FA',
          dark: '#000000',
        },
        card: {
          light: '#FFFFFF',
          dark: '#121212',
        },
        surface: {
          light: '#F1F5F9',
          dark: '#1C1C1E',
        },
        border: {
          light: '#E2E8F0',
          dark: '#2C2C2E',
        },
        ink: {
          light: '#0F172A',
          dark: '#FFFFFF',
        },
        muted: {
          light: '#64748B',
          dark: '#8E8E93',
        },
        accent: {
          DEFAULT: '#007AFF',
          dark: '#0A84FF',
          subtle: '#EFF6FF',
          subtleDark: '#152238',
        },
      },
      boxShadow: {
        sketch: '2px 2px 2px rgba(0,0,0,0.04)',
        sketchDark: '2px 2px 2px rgba(0,0,0,0.35)',
      },
    },
  },
  plugins: [],
}
