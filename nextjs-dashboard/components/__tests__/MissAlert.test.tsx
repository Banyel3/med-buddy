import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { beforeEach, describe, expect, it } from 'vitest';
import MissAlert from '../MissAlert';

const DISMISSED_KEY = 'medbuddy.dismissedMissAlerts';

describe('MissAlert', () => {
  beforeEach(() => {
    try {
      window.localStorage.removeItem(DISMISSED_KEY);
    } catch {
      // Tolerate jsdom storage edge cases.
    }
  });

  it('renders patient + miss date', () => {
    render(<MissAlert logId="log-a" patientName="Ban" missedAt="2026-05-24" />);
    expect(
      screen.getByText(/Ban missed a dose at 2026-05-24/),
    ).toBeInTheDocument();
  });

  it('dismiss button hides the alert', async () => {
    render(<MissAlert logId="log-b" patientName="Ban" missedAt="2026-05-24" />);
    await userEvent.click(screen.getByLabelText('Dismiss'));
    expect(screen.queryByText(/Ban missed a dose/)).not.toBeInTheDocument();
  });

  it('a fresh logId still shows the alert when another is dismissed', async () => {
    const { unmount } = render(
      <MissAlert logId="log-d" patientName="Ban" missedAt="2026-05-24" />,
    );
    await userEvent.click(screen.getByLabelText('Dismiss'));
    unmount();
    render(<MissAlert logId="log-e" patientName="Ban" missedAt="2026-05-25" />);
    expect(
      screen.getByText(/Ban missed a dose at 2026-05-25/),
    ).toBeInTheDocument();
  });
});
