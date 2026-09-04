import Link from 'next/link';

import DashboardPreview from '@/components/landing/DashboardPreview';
import PhonePreview from '@/components/landing/PhonePreview';
import { supabaseServer } from '@/lib/supabase/server';

export const dynamic = 'force-dynamic';

/**
 * The public landing page.
 *
 * This route used to redirect signed-in users straight to /dashboard, so the
 * live link was a portal door with nothing explaining what MedBuddy is.
 * Someone evaluating the product — usually a family member who was sent a
 * link — landed on a login box. Now the page explains itself and the CTA
 * adapts: "Go to your dashboard" if you're already signed in, "Sign in"
 * otherwise. No redirect, so there is no way back into the /↔/dashboard loop
 * that #20 fixed.
 *
 * Art direction: dusk -> day -> dusk. The dark folds and the light middle are
 * the design, not a theme, so every colour is painted explicitly.
 */
export default async function Home() {
  const supabase = supabaseServer();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  const signedIn = Boolean(user);

  return (
    <main>
      {/* ---------------- Hero (dusk) ---------------- */}
      <header className="relative isolate overflow-hidden bg-night pb-14 text-on-night sm:pb-24">
        <div
          aria-hidden="true"
          className="absolute -inset-x-[10%] -inset-y-[20%] -z-10 animate-drift bg-[radial-gradient(48%_42%_at_22%_8%,rgba(109,63,211,0.42),transparent_68%),radial-gradient(40%_38%_at_84%_26%,rgba(155,122,232,0.24),transparent_66%)]"
        />

        <Wrap>
          <nav className="relative z-[100] flex items-center justify-between gap-4 py-6">
            <Link
              className="inline-flex items-center gap-[0.6rem] font-display text-[1.12rem] font-extrabold tracking-[-0.02em] no-underline"
              href="/"
            >
              <span className="grid h-[30px] w-[30px] shrink-0 place-items-center rounded-full bg-primary">
                <span className="h-[11px] w-[11px] rounded-full bg-petal-blush ring-[3px] ring-white/20" />
              </span>
              MedBuddy
              <span className="ml-[0.15rem] border-l border-night-line pl-[0.55rem] font-body text-[0.82rem] font-medium tracking-[0.02em] text-on-night-dim">
                for family
              </span>
            </Link>
            <a
              className="text-[0.92rem] font-semibold text-on-night-dim no-underline transition-colors hover:text-on-night"
              href="#how"
            >
              How it works
            </a>
          </nav>

          <div className="grid items-center gap-10 pt-10 sm:gap-16 lg:grid-cols-2 lg:pt-[4.5rem]">
            <div className="flex flex-col items-start gap-[1.6rem]">
              <h1 className="type-display max-w-[15ch] animate-rise text-on-night [animation-delay:60ms]">
                Know they&apos;re okay, without hovering.
              </h1>
              <p className="type-lede max-w-[46ch] animate-rise text-on-night-dim [animation-delay:150ms]">
                MedBuddy reminds them when it&apos;s time, checks the dose
                actually happened, and tells you. You get one clear answer a day
                instead of a reason to call and ask.
              </p>
              <div className="flex animate-rise flex-wrap gap-[0.85rem] [animation-delay:240ms]">
                <Link
                  className="btn btn-primary"
                  href={signedIn ? '/dashboard' : '/login'}
                >
                  {signedIn ? 'Go to your dashboard' : 'Sign in to your dashboard'}
                </Link>
                <a className="btn btn-ghost-dark" href="#how">
                  See how a dose is checked
                </a>
              </div>
              <p className="flex animate-rise items-center gap-2 text-[0.85rem] text-on-night-dim [animation-delay:330ms]">
                <b className="font-semibold text-on-night">
                  They sign up in the mobile app.
                </b>
                &nbsp;This dashboard is for you.
              </p>
            </div>

            <div className="animate-rise [animation-delay:430ms]">
              <DashboardPreview variant="today" />
            </div>
          </div>
        </Wrap>
      </header>

      {/* ---------------- The question (day) ---------------- */}
      <section className="bg-surface py-16 text-ink sm:py-28">
        <Wrap>
          <div className="grid gap-7 sm:gap-14 lg:grid-cols-[1.1fr_1fr] lg:items-start">
            <h2 className="type-h2">There&apos;s one question, and it&apos;s small.</h2>
            <div className="flex flex-col gap-[1.15rem]">
              <p className="text-[1.02rem] text-ink/70">
                Did they take it today? That&apos;s it. That&apos;s the whole
                thing you want to know, and the only ways to find out have been
                to ask them again, or to not ask and quietly wonder.
              </p>
              <p className="text-[1.02rem] text-ink/70">
                Asking works once. By the fourth time it stops being care and
                starts being a check-up, and the person on the other end starts
                giving you the answer that ends the conversation.{' '}
                <strong className="font-semibold text-ink">
                  Nobody&apos;s lying. It&apos;s just that &ldquo;did you take
                  it?&rdquo; is a question that wears out.
                </strong>
              </p>
              <p className="border-t-2 border-outline pt-6 font-display text-[clamp(1.25rem,2.4vw,1.75rem)] font-bold leading-tight tracking-[-0.02em] text-primary">
                MedBuddy answers it without anyone having to ask.
              </p>
            </div>
          </div>
        </Wrap>
      </section>

      {/* ---------------- Two voices (day) ---------------- */}
      <section className="bg-surface py-12 text-ink sm:py-20">
        <Wrap>
          <SectionHead
            lede="They get a daily companion. You get a quiet read on how it's going. Same product, and it deliberately doesn't feel the same on both ends — theirs is warm and encouraging, yours stays out of the way."
            title="Two apps. One of them isn't yours."
          />
          <div className="mt-12 grid items-end gap-6 sm:gap-10 lg:grid-cols-[minmax(0,340px)_minmax(0,1fr)]">
            <div>
              <VoiceCap
                what="Reminders, the alarm, the camera check, a streak worth keeping"
                who="Their phone"
              />
              <PhonePreview />
            </div>
            <div>
              <VoiceCap
                what="One answer, then the detail if you want it"
                who="Your dashboard"
              />
              <DashboardPreview variant="alert" />
            </div>
          </div>
        </Wrap>
      </section>

      {/* ---------------- How verification works (dusk) ---------------- */}
      <section
        className="relative isolate overflow-hidden bg-night py-16 text-on-night sm:py-28"
        id="how"
      >
        <DuskWash />
        <Wrap>
          <SectionHead
            dark
            lede="A reminder alone only proves a phone buzzed. MedBuddy asks for a photo at the moment of the dose and checks it on the phone itself — three steps, in order, every time."
            title="How a dose gets checked"
          />
          <ol className="mt-10 border-t border-night-line">
            {VERIFY_STEPS.map((step, i) => (
              <li
                className="grid grid-cols-[auto_1fr] items-start gap-x-6 gap-y-[0.4rem] border-b border-night-line py-[1.6rem] md:grid-cols-[auto_minmax(0,20ch)_minmax(0,1fr)] md:items-baseline"
                key={step.name}
              >
                <span className="pt-[0.15rem] font-display text-[0.9rem] font-extrabold text-accent tabular-nums">
                  {String(i + 1).padStart(2, '0')}
                </span>
                <span className="font-display text-[1.08rem] font-bold tracking-[-0.015em]">
                  {step.name}
                </span>
                <span className="col-span-2 text-on-night-dim md:col-span-1">
                  {step.body}
                </span>
              </li>
            ))}
          </ol>
          <p className="mt-8 max-w-[62ch] text-sm text-on-night-dim">
            The face check confirms a person is present and close to the camera.
            It does not identify who they are, and we don&apos;t claim it does.
          </p>
        </Wrap>
      </section>

      {/* ---------------- Privacy ledger (day) ---------------- */}
      <section className="bg-surface py-16 text-ink sm:py-28">
        <Wrap>
          <SectionHead
            lede="The fastest way to make someone stop using an app like this is to make them feel watched. So the dashboard is deliberately narrow: it answers the dose question and stops there."
            title="Visibility, not surveillance."
          />
          <div className="mt-10 grid gap-6 sm:gap-12 md:grid-cols-2">
            <Ledger items={CAN_SEE} tone="yes" title="What you can see" />
            <Ledger items={CANNOT_SEE} tone="no" title="What you can't" />
          </div>
          <p className="mt-8 max-w-[62ch] text-sm text-ink/70">
            Linking is started by them, from their phone, and either of you can
            end it. Photos live in private storage and reach your browser
            through links that expire.
          </p>
        </Wrap>
      </section>

      {/* ---------------- The alarm (dusk) ---------------- */}
      <section className="relative isolate overflow-hidden bg-night py-16 text-on-night sm:py-28">
        <DuskWash />
        <Wrap>
          <SectionHead
            dark
            lede="A reminder you can swipe away is a reminder you will swipe away. Fifteen minutes after the dose time MedBuddy stops notifying and starts ringing — a real alarm, on the alarm channel, loud on a silent phone, screen lit, until there's a photo of the pill."
            title="If they don't, the phone stops being polite."
          />
          <div className="mt-8 flex flex-col">
            {LADDER.map((rung, i) => (
              <div
                className={`grid grid-cols-[5.5rem_1fr] items-baseline gap-5 border-b border-night-line py-[1.35rem] ${
                  i === 0 ? 'border-t' : ''
                }`}
                key={rung.at}
              >
                <span className="font-display text-[0.95rem] font-extrabold tracking-[-0.01em] text-accent tabular-nums">
                  {rung.at}
                </span>
                <span>
                  <span className="font-semibold text-on-night">
                    {rung.what}
                  </span>
                  <span className="mt-[0.15rem] block text-[0.9rem] text-on-night-dim">
                    {rung.note}
                  </span>
                </span>
              </div>
            ))}
          </div>

          <div className="mt-9 grid gap-4 md:grid-cols-2">
            <Mode tag="5 min ceiling" title="It always stops">
              An alarm that rings forever is one that gets uninstalled, or one
              that drains a phone left in another room. Five minutes, then it
              marks the dose missed and goes quiet by itself.
            </Mode>
            <Mode tag="Logged" title="They can always say no">
              &ldquo;I can&apos;t take it now&rdquo; is on the screen the whole
              time &mdash; for being out of refills, in a meeting, or told by a
              doctor to skip. It stops immediately, and you&apos;re told they
              said so. Someone answering is worth more to you than silence.
            </Mode>
          </div>
        </Wrap>
      </section>

      {/* ---------------- Close (dusk) ---------------- */}
      <section className="relative isolate overflow-hidden bg-night text-on-night">
        <DuskWash />
        <Wrap>
          <div className="flex flex-col items-center gap-6 py-16 text-center sm:py-28">
            <h2 className="type-h2 max-w-[18ch] text-on-night">
              Stop asking. Just know.
            </h2>
            <p className="type-lede max-w-[48ch] text-on-night-dim">
              {signedIn
                ? "You're signed in — your dashboard has today's answer."
                : "Sign in to see today's answer. If they haven't set up MedBuddy yet, they'll need the mobile app first — then they can send you a link code from their profile."}
            </p>
            <div className="flex flex-wrap justify-center gap-[0.85rem]">
              <Link
                className="btn btn-primary"
                href={signedIn ? '/dashboard' : '/login'}
              >
                {signedIn ? 'Open dashboard' : 'Sign in'}
              </Link>
              {!signedIn && (
                <Link className="btn btn-ghost-dark" href="/login?mode=signup">
                  Create an account
                </Link>
              )}
            </div>
          </div>

          <div className="flex flex-wrap items-center justify-between gap-x-8 gap-y-4 border-t border-night-line py-9 text-[0.85rem] text-on-night-dim">
            <span>&copy; 2026 MedBuddy</span>
            <span className="flex flex-wrap gap-6">
              <Link className="no-underline hover:text-on-night" href="/privacy">
                Privacy
              </Link>
              <Link className="no-underline hover:text-on-night" href="/login">
                Sign in
              </Link>
            </span>
          </div>
        </Wrap>
      </section>
    </main>
  );
}

/* ---------------- Content ---------------- */

const VERIFY_STEPS = [
  {
    name: 'The reminder',
    body: 'At the time they chose, their phone asks for the dose by name. Not a generic ping — "Time for your Amlodipine."',
  },
  {
    name: 'The photo',
    body: 'They take one picture holding the pill. The phone looks for a face and for a pill in the same frame, so the photo has to be them, now, with the medication actually in hand.',
  },
  {
    name: 'The check',
    body: "Both checks run on their phone, not on a server. If the picture is too dark or the pill isn't visible, it says so and asks for another. A confidence score that didn't clear the bar is reported honestly, never rounded up into a pass.",
  },
];

const LADDER = [
  {
    at: 'On time',
    what: 'A reminder, by name',
    note: '"Time for your Amlodipine." Take it, and nothing else happens all day.',
  },
  {
    at: '+15 min',
    what: 'The alarm goes off',
    note: 'Rings on the alarm channel, so a muted phone still sounds. Screen wakes, full screen, vibrating. It starts firm and gets louder over the first twenty seconds.',
  },
  {
    at: 'Until verified',
    what: "It doesn't stop for a swipe",
    note: 'A photo of the pill is the only thing that ends it early. Emergency calls and phone settings always get through.',
  },
  {
    at: '+5 min',
    what: 'It gives up on its own',
    note: "Marked missed, and you're told. Once. The streak resets quietly — no shame copy, no sad mascot.",
  },
];

const CAN_SEE = [
  'Whether today’s dose was taken, and when',
  'The verification photo, for 30 days',
  'A month of history: verified, late, or missed',
  'Their current streak',
  'A notification when a dose is missed',
  'When they stopped the alarm to say they couldn’t take one',
];

const CANNOT_SEE = [
  'Their location, ever',
  'Anything else on their phone',
  'Their messages, calls, or other apps',
  'Photos older than 30 days. They delete themselves',
  'Anything at all, until they link you',
];

/* ---------------- Building blocks ---------------- */

function Wrap({ children }: { children: React.ReactNode }) {
  return (
    <div className="mx-auto w-full max-w-[1180px] px-6 sm:px-10 lg:px-16">
      {children}
    </div>
  );
}

/** Ambient evening light behind a dark fold. Decorative only. */
function DuskWash() {
  return (
    <div
      aria-hidden="true"
      className="absolute -inset-x-[10%] -inset-y-[20%] -z-10 animate-drift bg-[radial-gradient(48%_42%_at_22%_8%,rgba(109,63,211,0.32),transparent_68%),radial-gradient(40%_38%_at_84%_26%,rgba(155,122,232,0.18),transparent_66%)]"
    />
  );
}

function SectionHead({
  title,
  lede,
  dark = false,
}: {
  title: string;
  lede: string;
  dark?: boolean;
}) {
  return (
    <div className="flex max-w-[62ch] flex-col gap-4">
      <h2 className={`type-h2 ${dark ? 'text-on-night' : 'text-ink'}`}>
        {title}
      </h2>
      <p
        className={`type-lede ${dark ? 'text-on-night-dim' : 'text-ink/70'}`}
      >
        {lede}
      </p>
    </div>
  );
}

function VoiceCap({ who, what }: { who: string; what: string }) {
  return (
    <div className="mb-4 flex flex-col gap-[0.35rem]">
      <span className="font-display text-[1.05rem] font-extrabold tracking-[-0.015em]">
        {who}
      </span>
      <span className="text-[0.85rem] text-ink/70">{what}</span>
    </div>
  );
}

function Ledger({
  title,
  items,
  tone,
}: {
  title: string;
  items: string[];
  tone: 'yes' | 'no';
}) {
  const yes = tone === 'yes';
  return (
    <div>
      <h3
        className={`mb-1 border-b-2 pb-[0.85rem] text-base font-bold ${
          yes ? 'border-verified text-verified' : 'border-outline text-ink/70'
        }`}
      >
        {title}
      </h3>
      <ul className="m-0 list-none p-0">
        {items.map((item) => (
          <li
            className={`grid grid-cols-[1.4rem_1fr] gap-[0.6rem] border-b border-outline py-[0.85rem] text-[0.95rem] ${
              yes ? '' : 'text-ink/70'
            }`}
            key={item}
          >
            <em
              className={`text-center font-bold not-italic ${
                yes ? 'text-verified' : 'text-ink/70'
              }`}
            >
              {yes ? '✓' : '—'}
            </em>
            {item}
          </li>
        ))}
      </ul>
    </div>
  );
}

function Mode({
  title,
  tag,
  children,
}: {
  title: string;
  tag: string;
  children: React.ReactNode;
}) {
  return (
    <div className="rounded-[20px] border border-night-line bg-night-raised p-[1.4rem]">
      <h4 className="mb-2 flex items-center gap-2 text-[0.95rem] font-bold">
        {title}
        <span className="rounded-full border border-night-line bg-night px-2 py-[0.18rem] font-body text-[0.68rem] font-semibold uppercase tracking-[0.04em] text-accent">
          {tag}
        </span>
      </h4>
      <p className="text-[0.9rem] text-on-night-dim">{children}</p>
    </div>
  );
}
