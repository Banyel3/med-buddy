# Product

## Register

product

## Users

**Patient (mobile app).** Younger adult, 18-35, high tech-comfort. Already lives in their phone. May be managing a chronic prescription (asthma, mental health, contraception, post-acute), a temporary course (antibiotic, post-op), or someone else's care alongside their own. Treats their phone as a daily companion, not a tool. Will abandon any app that nags, shames, or feels like medical paperwork.

**Monitor (Next.js dashboard).** A family member with emotional stake: spouse, adult child, parent of a young-adult patient. Wants a clear "yes / no / something's wrong" read at a glance, not a clinician's chart. Logs in once or twice a day, often on a desktop or tablet at home or at work. Wants reassurance more than data.

The product is mostly used in low-stakes daily moments (morning coffee, brushing teeth) punctuated by occasional high-stakes ones (a missed dose, a verified photo that looks off). Both surfaces have to handle that swing.

## Product Purpose

MedBuddy makes daily medication adherence feel like a daily ritual, not a clinical obligation, and gives a trusted family member quiet visibility without surveillance. The patient app reminds, verifies (face + pill, on-device), and celebrates. The monitor dashboard answers "is they OK today?" in under three seconds.

Success looks like: a patient who actually opens the app at dose time and doesn't resent it; a family member who closes the dashboard reassured instead of worried.

## Brand Personality

Cheerful, encouraging, human.

The voice is a thoughtful friend who happens to remember your meds, not a nurse with a checklist. Microcopy uses contractions, present tense, and second person ("Time for your morning dose"; "You did this seven days in a row"). Never "Patient ID 4729 has missed a scheduled administration."

The patient surface (pink/rose) leans into warmth and small celebration: streak moments, a verified-photo flash of color, a soft success state. The monitor surface (violet) is the same brand seen from a calmer vantage point: less playful, more observant, but still recognizably the same product. Two voices, one product.

## Anti-references

**Not a clinical portal.** No sterile white-on-blue. No grids of forms. No "Submit Medical Information" buttons. MyChart and its lookalikes are the wrong genre entirely.

**Not pharma-corporate.** No stock photos of smiling racially-balanced cast members. No navy-and-gold trust-by-aesthetic. No serif headlines pretending to be a legacy brand.

**Not gamified into anxiety.** Streaks are visible but breakable without punishment. No mascots that "look sad." No streak-loss confetti. No "Don't break your 47-day streak!" red alerts. Headspace and Duolingo found a great hook for habit apps; medical adherence is the wrong context to copy them, because a broken streak in MedBuddy may mean a real missed dose, not a missed lesson.

**Not generic SaaS.** Dashboard avoids the big-number-hero template, identical card grids, and Recharts defaults. Patient app avoids "card with icon + heading + body" repeated five times down the screen.

## Design Principles

1. **Two voices, one product.** Mobile = warm pink, encouragement, daily companion. Dashboard = quiet violet, observant, reassurance. The same brand DNA expressed in two registers. Never run them together; never let one bleed into the other's tone.

2. **Celebrate without pressuring.** Streaks, verified moments, "you did it" beats are present and visible. They never use shame, urgency, or loss-aversion. A broken streak resets quietly. Anxiety has no place in a medical adherence loop.

3. **Three-second reassurance.** The monitor dashboard answers one question first: did they take it today, yes or no. Everything else (calendar, photos, charts) supports that answer; nothing competes with it. If the answer takes more than three seconds to read, the layout has failed.

4. **The phone trusts the user.** Patient app skips confirmations on reversible actions, doesn't double-check the obvious, doesn't make people prove they read a tooltip. High-tech-comfort users get talked to like adults.

5. **The medical stakes are real.** Verification (face + pill) is the product's hard core. Treat it with respect: clear capture state, honest confidence rendering, never decorative. A failed verification is a real signal, not a UI moment. The cheerful surface around it is allowed to be soft; the verification flow itself is allowed to be plain.

## Accessibility & Inclusion

**WCAG 2.2 AA minimum across both surfaces.** Pink (`#E04D8C` on `#FFF7FA`) and violet (`#6D3FD3` on `#FBF7FE`) primaries chosen at lightness levels that meet 4.5:1 against tinted-white surfaces, 3:1 for large text. Verify any custom hue or accent before shipping.

**Reduced motion** respected on both surfaces. Streak celebrations and verified-state transitions degrade to instant state changes when `prefers-reduced-motion: reduce` is set. No motion is ever load-bearing for understanding state.

**Color is never the only signal.** Verified / pending / missed states pair color with iconography and text label. Color-blindness safe: the pink-vs-green verified pair is fine on hue, but the patient app never uses green-vs-red as a sole differentiator.

**Touch targets ≥44pt on mobile**, ≥36px on dashboard interactive elements. Hit areas larger than visual targets where the design allows.

**Plain language.** Microcopy reads at roughly a sixth-grade level. Medical terminology only when the user supplied it (their own medication name). No "compliance," "administration," "regimen" in user-facing copy.
