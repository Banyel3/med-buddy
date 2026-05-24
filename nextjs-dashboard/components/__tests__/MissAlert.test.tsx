import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it } from 'vitest';
import MissAlert from '../MissAlert';

describe('MissAlert', () => {
  it('renders patient + miss date', () => {
    render(<MissAlert patientName="Ban" missedAt="2026-05-24" />);
    expect(screen.getByText(/Ban missed a dose at 2026-05-24/)).toBeInTheDocument();
  });

  it('dismiss button hides the alert', async () => {
    render(<MissAlert patientName="Ban" missedAt="2026-05-24" />);
    await userEvent.click(screen.getByLabelText('Dismiss'));
    expect(screen.queryByText(/Ban missed a dose/)).not.toBeInTheDocument();
  });
});
