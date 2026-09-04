/**
 * A faithful rendering of the real dashboard, built from the same tokens the
 * live components use. This is the landing page's imagery: `PRODUCT.md` rules
 * out the stock-photo route ("no stock photos of smiling cast members"), and
 * the honest asset for this product is the product.
 *
 * Two folds need different framings, hence the variant:
 *   `today` — the three-second answer, streak and month. Used in the hero.
 *   `alert` — a miss followed by a recovery. Used in "Two apps".
 */
export default function DashboardPreview({
  variant = 'today',
}: {
  variant?: 'today' | 'alert';
}) {
  return (
    <div
      aria-label={
        variant === 'today'
          ? "The MedBuddy dashboard: today's dose verified at 8:12 in the morning, a 12-day streak, and a month of mostly verified days with one missed."
          : 'The MedBuddy dashboard showing a missed dose on Tuesday alongside a verified dose today.'
      }
      className="overflow-hidden rounded-[22px] border border-outline bg-surface text-ink shadow-[0_30px_60px_-28px_rgba(20,16,30,0.75)]"
      role="img"
    >
      <div className="flex items-center justify-between gap-3 border-b border-outline bg-white px-[1.1rem] py-[0.85rem]">
        <span className="inline-flex items-center gap-2 font-display text-[0.85rem] font-bold tracking-[-0.01em]">
          <i className="grid h-5 w-5 shrink-0 place-items-center rounded-full bg-primary not-italic">
            <span className="h-[7px] w-[7px] rounded-full bg-petal-blush" />
          </i>
          Dad &middot; Amlodipine
        </span>
        <span className="text-[0.78rem] text-ink/60">
          {variant === 'today' ? 'Today, 9:04 AM' : 'Updated just now'}
        </span>
      </div>

      {variant === 'alert' ? (
        <div className="grid gap-[0.85rem] p-4">
          <div className="flex items-start gap-3 rounded-[18px] border border-warning bg-warning-soft px-4 py-[0.95rem]">
            <span aria-hidden="true" className="text-[1.15rem] leading-tight">
              &#9888;&#65039;
            </span>
            <span>
              <span className="block font-semibold">
                Dad missed a dose on Tuesday
              </span>
              <span className="text-sm text-ink/70">
                Might be worth a text, not an alarm.
              </span>
            </span>
          </div>
          <TodayPanel sub="8:12 AM — back on track." title="Verified today" />
        </div>
      ) : (
        <div className="grid gap-[0.85rem] p-4 sm:grid-cols-[1.15fr_1fr]">
          <TodayPanel
            sub="Dad took today's dose at 8:12 AM."
            title="Verified"
          />

          <Panel title="Streak">
            <div className="flex items-baseline gap-2">
              <span className="font-display text-[2.6rem] font-extrabold leading-none tracking-[-0.04em] text-primary tabular-nums">
                12
              </span>
              <span className="text-[0.85rem] font-semibold text-ink/70">
                days
                <br />
                in a row
              </span>
            </div>
            <p className="mt-[0.55rem] text-[0.78rem] text-ink/70">
              Longest: 31 days
            </p>
          </Panel>

          <Panel className="sm:col-span-2" title="September">
            <Calendar />
            <div className="mt-[0.7rem] flex flex-wrap gap-[0.85rem] text-[0.72rem] text-ink/70">
              <LegendSwatch className="bg-verified" label="Verified" />
              <LegendSwatch className="bg-warning" label="Late" />
              <LegendSwatch
                className="border border-danger bg-danger-soft"
                label="Missed"
              />
            </div>
          </Panel>
        </div>
      )}
    </div>
  );
}

/** The three-second answer. Status colour always pairs with an icon and a word. */
function TodayPanel({ title, sub }: { title: string; sub: string }) {
  return (
    <div className="flex flex-col gap-[0.15rem] rounded-[18px] bg-verified p-[1.1rem] text-white">
      <span className="mb-2 inline-flex items-center gap-[0.4rem] self-start rounded-full bg-white/20 px-[0.6rem] py-[0.22rem] text-[0.72rem] font-semibold">
        &#10003; Photo checked
      </span>
      <span className="font-display text-[1.85rem] font-extrabold leading-tight tracking-[-0.02em]">
        {title}
      </span>
      <span className="text-[0.85rem] text-white/90">{sub}</span>
    </div>
  );
}

function Panel({
  title,
  children,
  className = '',
}: {
  title: string;
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <div
      className={`rounded-[18px] border border-outline bg-white px-4 py-[0.95rem] ${className}`}
    >
      <div className="mb-[0.6rem] font-display text-[0.8rem] font-bold text-ink/70">
        {title}
      </div>
      {children}
    </div>
  );
}

/** A real month: mostly verified, one miss, two late, the rest still to come. */
const CALENDAR_DAYS = [
  'v', 'v', 'v', 'l', 'v', 'v', 'v', 'v', 'm', 'v', 'v', 'v', 'v', 'v',
  'v', 'v', 'l', 'v', 'v', 'v', 'v', 'u', 'u', 'u', 'u', 'u', 'u', 'u',
] as const;

const DAY_STYLES: Record<string, string> = {
  v: 'bg-verified',
  l: 'bg-warning',
  m: 'border border-danger bg-danger-soft',
  u: 'border border-outline bg-transparent',
};

function Calendar() {
  return (
    <div className="grid grid-cols-[repeat(14,minmax(0,1fr))] gap-1">
      {CALENDAR_DAYS.map((day, i) => (
        <span
          className={`block aspect-square rounded-[5px] ${DAY_STYLES[day]}`}
          key={i}
        />
      ))}
    </div>
  );
}

function LegendSwatch({
  className,
  label,
}: {
  className: string;
  label: string;
}) {
  return (
    <span className="inline-flex items-center gap-[0.32rem]">
      <b className={`inline-block h-[10px] w-[10px] shrink-0 rounded-[3px] ${className}`} />
      {label}
    </span>
  );
}
