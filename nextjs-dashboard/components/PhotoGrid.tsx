import Image from 'next/image';
import { format } from 'date-fns';

import type { ComplianceLog } from '@/lib/supabase/types';

export default function PhotoGrid({ logs }: { logs: ComplianceLog[] }) {
  const withPhotos = logs.filter((l) => l.image_url);
  return (
    <div className="bg-white rounded-3xl border border-outline p-5">
      <h3 className="text-lg font-bold text-ink mb-3">Verification photos</h3>
      {withPhotos.length === 0 ? (
        <p className="text-ink/60 text-sm">No verifications yet.</p>
      ) : (
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
          {withPhotos.slice(0, 12).map((log) => (
            <div
              key={log.id}
              className="rounded-2xl overflow-hidden bg-surface-container relative aspect-square"
            >
              {log.image_url && (
                <Image
                  src={log.image_url}
                  alt="verification"
                  fill
                  sizes="(max-width: 768px) 50vw, 25vw"
                  className="object-cover"
                />
              )}
              <div className="absolute bottom-0 inset-x-0 bg-black/60 text-white text-xs px-2 py-1">
                {log.verified_at
                  ? format(new Date(log.verified_at), 'MMM d • h:mm a')
                  : log.date}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
