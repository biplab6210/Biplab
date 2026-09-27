import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './app/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        ink: '#14171F',
        paper: '#F7F5F0',
        brand: {
          50: '#EFF6FF',
          100: '#DCEAFE',
          300: '#8FBBF8',
          500: '#2F6FED',
          600: '#1F55C7',
          700: '#173F97',
          900: '#0E244F',
        },
        accent: {
          400: '#F4A340',
          500: '#EB8B1B',
          600: '#C86F0E',
        },
      },
      fontFamily: {
        display: ['var(--font-display)'],
        body: ['var(--font-body)'],
      },
      borderRadius: {
        card: '14px',
      },
      boxShadow: {
        card: '0 1px 2px rgba(20,23,31,0.04), 0 8px 24px -12px rgba(20,23,31,0.18)',
      },
      maxWidth: {
        prose: '72ch',
      },
    },
  },
  plugins: [],
};

export default config;
