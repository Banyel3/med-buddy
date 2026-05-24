import type { Streak } from '@/lib/supabase/types';

export default function StreakWidget({ streak }: { streak: Streak | null }) {
  return (
    <div className="bg-coral-gradient text-white rounded-3xl p-6 shadow-lg">
      <div className="text-3xl">🔥</div>
      <div className="text-5xl font-black mt-2">
        {streak?.current_streak ?? 0}
      </div>
      <div className="text-sm uppercase opacity-90 tracking-wide">
        day streak
      </div>
      <div className="text-xs opacity-80 mt-3">
        Longest: {streak?.longest_streak ?? 0} days
      </div>
    </div>
  );
}
