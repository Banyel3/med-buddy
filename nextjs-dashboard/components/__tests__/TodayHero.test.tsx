import { render, screen } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import TodayHero from '../TodayHero';

describe('TodayHero', () => {
  it('renders verified state', () => {
    render(<TodayHero status="verified" patientName="Ban" />);
    expect(screen.getByText('Verified')).toBeInTheDocument();
    expect(screen.getByText(/Ban took today/)).toBeInTheDocument();
  });

  it('renders missed state with patient name', () => {
    render(<TodayHero status="missed" patientName="Ban" />);
    expect(screen.getByText('Missed')).toBeInTheDocument();
    expect(screen.getByText(/Ban hasn't logged today/)).toBeInTheDocument();
  });

  it('distinguishes a declined dose from silence', () => {
    // Same status, different sentence: a monitor needs to know the difference
    // between "they answered and said no" and "nothing happened".
    render(
      <TodayHero
        patientName="Ban"
        skippedAt="2026-09-04T08:40:00.000Z"
        status="missed"
      />,
    );
    expect(screen.getByText(/Ban said they couldn't take it/)).toBeInTheDocument();
    expect(screen.queryByText(/hasn't logged today/)).not.toBeInTheDocument();
  });

  it('falls back to the plain missed copy when the timestamp is unusable', () => {
    render(
      <TodayHero patientName="Ban" skippedAt="not-a-date" status="missed" />,
    );
    expect(screen.getByText(/an unknown time/)).toBeInTheDocument();
  });

  it('renders no-log fallback', () => {
    render(<TodayHero status="no-log" patientName="Ban" />);
    expect(screen.getByText('No log yet')).toBeInTheDocument();
  });

  it('renders pending state', () => {
    render(<TodayHero status="pending" patientName="Ban" />);
    expect(screen.getByText('Pending')).toBeInTheDocument();
  });

  it('renders late state', () => {
    render(<TodayHero status="late" patientName="Ban" />);
    expect(screen.getByText('Late')).toBeInTheDocument();
  });
});
