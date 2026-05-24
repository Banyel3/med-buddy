import { render, screen } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import StreakWidget from '../StreakWidget';

describe('StreakWidget', () => {
  it('renders zero when streak is null', () => {
    render(<StreakWidget streak={null} />);
    expect(screen.getByText('0')).toBeInTheDocument();
    expect(screen.getByText(/Longest: 0 days/)).toBeInTheDocument();
  });

  it('renders current + longest streak numbers', () => {
    render(
      <StreakWidget
        streak={{
          id: '1',
          user_id: 'u',
          current_streak: 7,
          longest_streak: 14,
          last_verified_date: '2026-05-24',
          updated_at: '2026-05-24T00:00:00.000Z',
        }}
      />,
    );
    expect(screen.getByText('7')).toBeInTheDocument();
    expect(screen.getByText(/Longest: 14 days/)).toBeInTheDocument();
  });
});
