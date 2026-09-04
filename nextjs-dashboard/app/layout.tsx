import './globals.css';
import type { Metadata } from 'next';
import type { ReactNode } from 'react';

export const metadata: Metadata = {
  title: 'MedBuddy for Family',
  description:
    'Know they took it, without asking again. MedBuddy reminds them, checks '
    + 'the dose actually happened, and gives you one clear answer a day.',
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
