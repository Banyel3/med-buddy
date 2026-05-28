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
