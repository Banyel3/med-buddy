import type { Config } from 'tailwindcss';

// MedBuddy family dashboard — violet identity, distinct from the mobile app
// (pink/rose). Hue ~290 OKLCH carries the brand. Red reserved for danger only
// (alerts must read as alerts).
const config: Config = {
  content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: '#6D3FD3', // violet
        secondary: '#4FA86A', // sage (verified) — fills only, see `verified`
        accent: '#9B7AE8', // lavender
        surface: '#FBF7FE', // lavender-tinted white
        'surface-container': '#EEE7F7',
        warning: '#E8B23A',
        'warning-soft': '#FBF0D8',
        danger: '#BA1A1A',
        'danger-soft': '#F7DEDE',
        outline: '#D8CCE9',
        ink: '#1C1626', // deep violet-black

        // Sage dark enough to carry white text at 4.5:1. `secondary` is the
        // lighter fill; use this one whenever text sits on top.
        verified: '#3D8452',

        // Dusk register — the landing page's dark folds. The dashboard itself
        // stays on the light canvas so data reads first.
        night: '#14101E',
        'night-raised': '#221A33',
        'night-line': '#342A4A',
        'on-night': '#EDE6F7',
        'on-night-dim': '#B3A5CC',

        // Petal — the mobile app's palette. Used ONLY inside the phone
        // rendering on the landing page, where we depict the other surface.
        // The Two-Voice Rule (DESIGN.md) forbids it anywhere else here.
        petal: '#E04D8C',
        'petal-blush': '#FFB6CB',
        'petal-white': '#FFF7FA',
        'petal-ink': '#2A171F',
        'petal-line': '#E8CFD8',
      },
      fontFamily: {
        display: ['"Plus Jakarta Sans"', 'system-ui', 'sans-serif'],
        body: ['"Be Vietnam Pro"', 'system-ui', 'sans-serif'],
      },
      backgroundImage: {
        // Name retained for component compat. Underlying colors are violet.
        'coral-gradient': 'linear-gradient(135deg, #9B7AE8 0%, #6D3FD3 100%)',
        'petal-gradient': 'linear-gradient(135deg, #FFB6CB 0%, #E04D8C 100%)',
      },
      borderRadius: {
        '4xl': '32px',
      },
      keyframes: {
        // Ambient evening light behind the dark folds. Slow enough to read as
        // atmosphere rather than motion.
        drift: {
          from: { transform: 'translate3d(-2%, -1%, 0) scale(1)' },
          to: { transform: 'translate3d(3%, 2%, 0) scale(1.08)' },
        },
        // Page-load choreography. Elements rest at their final state and the
        // animation plays backwards from a displaced start, so if it never
        // runs the page still reads correctly.
        rise: {
          from: { opacity: '0', transform: 'translate3d(0, 16px, 0)' },
          to: { opacity: '1', transform: 'none' },
        },
      },
      animation: {
        drift: 'drift 26s cubic-bezier(0.22, 1, 0.36, 1) infinite alternate',
        rise: 'rise 800ms cubic-bezier(0.22, 1, 0.36, 1) backwards',
      },
      transitionTimingFunction: {
        ease: 'cubic-bezier(0.22, 1, 0.36, 1)',
      },
    },
  },
  plugins: [],
};

export default config;
