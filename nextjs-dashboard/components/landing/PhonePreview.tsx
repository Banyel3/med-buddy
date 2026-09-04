/**
 * The mobile app, rendered in its own Petal (pink) palette.
 *
 * This is the one place on this surface where Petal is allowed. DESIGN.md's
 * Two-Voice Rule says the family dashboard never uses Petal Rose — but "two
 * voices, one product" is the thing this fold exists to explain, and you
 * cannot show it without showing both. This is a picture of the other
 * surface, not a borrowing of its palette. Nothing outside this component
 * may use a `petal-*` token.
 */
export default function PhonePreview() {
  return (
    <div
      aria-label="The MedBuddy mobile app: a pink twelve-day streak card, and today's Amlodipine dose at 8:00 in the morning with a Take it now button."
      className="flex flex-col gap-[0.7rem] rounded-[30px] border border-petal-line bg-petal-white p-[0.85rem] text-petal-ink shadow-[0_24px_48px_-26px_rgba(42,23,31,0.4)]"
      role="img"
    >
      <span className="mx-auto mb-[0.35rem] mt-[0.15rem] h-[5px] w-[88px] rounded-full bg-petal-line" />

      <p className="px-[0.3rem] text-[0.82rem] text-[#6E5560]">
        Good morning
        <b className="block font-display text-[1.15rem] font-extrabold tracking-[-0.02em] text-petal-ink">
          Dad &#128075;
        </b>
      </p>

      <div className="rounded-[22px] bg-petal-gradient px-[1.2rem] py-[1.1rem] text-white">
        <b className="block font-display text-[3.2rem] font-extrabold leading-none tracking-[-0.045em] tabular-nums">
          12
        </b>
        <span className="text-[0.8rem] opacity-95">days in a row. Nice.</span>
      </div>

      <div className="flex flex-col gap-[0.85rem] rounded-[22px] border border-petal-line bg-white p-4">
        <div className="flex items-baseline justify-between gap-3">
          <span className="font-display text-base font-bold">Amlodipine</span>
          <span className="text-[0.82rem] text-[#6E5560] tabular-nums">
            8:00 AM
          </span>
        </div>
        <span className="block rounded-full bg-petal py-3 text-center text-[0.9rem] font-semibold text-white shadow-[0_8px_18px_rgba(224,77,140,0.3)]">
          Take it now
        </span>
      </div>
    </div>
  );
}
