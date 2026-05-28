import type { Config } from 'tailwindcss';

// MedBuddy monitor dashboard — violet identity, distinct from the
// patient mobile app (pink/rose). Hue ~290 OKLCH carries the brand.
// Red reserved for danger only (alerts must read as alerts).
const config: Config = {
  content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: '#6D3FD3', // violet
        secondary: '#4FA86A', // sage (verified)
        accent: '#9B7AE8', // lavender
        surface: '#FBF7FE', // lavender-tinted white
        'surface-container': '#EEE7F7',
        warning: '#E8B23A',
        danger: '#BA1A1A',
        outline: '#D8CCE9',
        ink: '#1C1626', // deep violet-black
      },
      fontFamily: {
        display: ['"Plus Jakarta Sans"', 'system-ui', 'sans-serif'],
        body: ['"Be Vietnam Pro"', 'system-ui', 'sans-serif'],
      },
      backgroundImage: {
        // Name retained for component compat. Underlying colors are violet.
        'coral-gradient':
          'linear-gradient(135deg, #9B7AE8 0%, #6D3FD3 100%)',
      },
      borderRadius: {
        '4xl': '32px',
      },
    },
  },
  plugins: [],
};

export default config;
