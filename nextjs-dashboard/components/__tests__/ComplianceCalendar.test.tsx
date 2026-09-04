import { render, screen } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import ComplianceCalendar from '../ComplianceCalendar';
import type { ComplianceLog } from '@/lib/supabase/types';

const sample: ComplianceLog[] = [
  {
    id: '1',
    medication_id: 'm',
    user_id: 'u',
    date: new Date().toISOString().slice(0, 10),
    status: 'verified',
    image_url: null,
    verified_at: null,
    face_confidence: null,
    pill_confidence: null,
    skipped_at: null,
  },
];

describe('ComplianceCalendar', () => {
  it('renders the current month header', () => {
    render(<ComplianceCalendar logs={sample} />);
    const headers = screen.getAllByRole('heading');
    expect(headers[0].textContent).toMatch(
      new Date().toLocaleString('en-US', { month: 'long' }),
    );
  });

  it('renders today cell with verified color class', () => {
    const { container } = render(<ComplianceCalendar logs={sample} />);
    const verifiedCells = container.querySelectorAll('.bg-secondary');
    expect(verifiedCells.length).toBeGreaterThan(0);
  });

  it('renders all 3 legend entries', () => {
    render(<ComplianceCalendar logs={[]} />);
    expect(screen.getByText('Verified')).toBeInTheDocument();
    expect(screen.getByText('Late')).toBeInTheDocument();
    expect(screen.getByText('Missed')).toBeInTheDocument();
  });
});
