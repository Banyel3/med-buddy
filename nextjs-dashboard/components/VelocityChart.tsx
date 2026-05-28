'use client';

import {
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import { format } from 'date-fns';

import type { ComplianceLog } from '@/lib/supabase/types';

export default function VelocityChart({ logs }: { logs: ComplianceLog[] }) {
  const today = new Date();
  const days = Array.from({ length: 7 }, (_, i) => {
    const d = new Date(today);
    d.setDate(today.getDate() - (6 - i));
    return d;
  });

  const data = days.map((d) => {
    const key = d.toISOString().slice(0, 10);
    const log = logs.find((l) => l.date === key);
    return {
      day: format(d, 'EEE'),
      score:
        log?.status === 'verified'
          ? 1
          : log?.status === 'late'
            ? 0.5
            : 0,
    };
  });

  return (
    <div className="bg-white rounded-3xl border border-outline p-5">
      <h3 className="text-lg font-bold text-ink mb-3">7-day velocity</h3>
      <div className="h-44">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={data}>
            <CartesianGrid strokeDasharray="3 3" stroke="#F2EDEC" />
            <XAxis dataKey="day" stroke="#1C1626" />
            <YAxis
              hide
              domain={[0, 1]}
              tickFormatter={(v) => `${v * 100}%`}
            />
            <Tooltip
              formatter={(v: number) => `${Math.round(v * 100)}%`}
              cursor={{ fill: '#EEE7F7' }}
            />
            <Bar dataKey="score" fill="#6D3FD3" radius={[8, 8, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
