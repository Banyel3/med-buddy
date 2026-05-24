import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        // Matches MedBuddy mobile palette (PRD §8.1).
        primary: '#AE2F34',
        secondary: '#006E29',
        accent: '#FF6B6B',
        surface: '#FDF8F8',
        'surface-container': '#F2EDEC',
        warning: '#E8C426',
        danger: '#BA1A1A',
        outline: '#CBBCBB',
        ink: '#1E1A1A',
      },
      fontFamily: {
        display: ['"Plus Jakarta Sans"', 'system-ui', 'sans-serif'],
        body: ['"Be Vietnam Pro"', 'system-ui', 'sans-serif'],
      },
      backgroundImage: {
        'coral-gradient':
          'linear-gradient(135deg, #FF6B6B 0%, #AE2F34 100%)',
      },
      borderRadius: {
        '4xl': '32px',
      },
    },
  },
  plugins: [],
};

export default config;
