import '@testing-library/jest-dom/vitest';
import { vi } from 'vitest';

// Stub Supabase env so client modules don't throw on import.
process.env.NEXT_PUBLIC_SUPABASE_URL ??= 'https://placeholder.supabase.co';
process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ??= 'placeholder';

// jsdom doesn't implement matchMedia (recharts touches it).
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation((query: string) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  })),
});

// Recharts uses ResizeObserver in jsdom.
class _RO {
  observe() {}
  unobserve() {}
  disconnect() {}
}
(globalThis as unknown as { ResizeObserver: typeof _RO }).ResizeObserver = _RO;
