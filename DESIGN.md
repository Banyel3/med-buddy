---
name: MedBuddy
description: Daily medication adherence with on-device verification, told in two voices: a warm pink patient app and a quiet violet monitor dashboard.
colors:
  patient-primary: "#E04D8C"
  patient-accent: "#FFB6CB"
  patient-secondary: "#6CB57E"
  patient-surface: "#FFF7FA"
  patient-surface-container: "#F7E9EE"
  patient-ink: "#2A171F"
  patient-outline: "#E8CFD8"
  patient-error: "#C6294B"
  patient-warning: "#E8B23A"
  patient-dark-surface: "#1B1015"
  patient-dark-surface-container: "#251820"
  patient-dark-ink: "#F7E3EC"
  monitor-primary: "#6D3FD3"
  monitor-accent: "#9B7AE8"
  monitor-secondary: "#4FA86A"
  monitor-surface: "#FBF7FE"
  monitor-surface-container: "#EEE7F7"
  monitor-ink: "#1C1626"
  monitor-outline: "#D8CCE9"
  monitor-danger: "#BA1A1A"
  monitor-warning: "#E8B23A"
typography:
  display:
    fontFamily: "Plus Jakarta Sans, system-ui, sans-serif"
    fontSize: "56px"
    fontWeight: 800
    lineHeight: 1.05
    letterSpacing: "-1.5px"
  headline:
    fontFamily: "Plus Jakarta Sans, system-ui, sans-serif"
    fontSize: "28px"
    fontWeight: 700
    lineHeight: 1.15
    letterSpacing: "-0.3px"
  title:
    fontFamily: "Plus Jakarta Sans, system-ui, sans-serif"
    fontSize: "18px"
    fontWeight: 600
    lineHeight: 1.3
  body:
    fontFamily: "Be Vietnam Pro, system-ui, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.5
  body-small:
    fontFamily: "Be Vietnam Pro, system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.45
  label:
    fontFamily: "Be Vietnam Pro, system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 600
    letterSpacing: "0.3px"
  streak:
    fontFamily: "Plus Jakarta Sans, system-ui, sans-serif"
    fontSize: "88px"
    fontWeight: 900
    lineHeight: 1
    letterSpacing: "-3px"
rounded:
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "32px"
  full: "9999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "32px"
  2xl: "48px"
  3xl: "64px"
components:
  button-primary-patient:
    backgroundColor: "{colors.patient-primary}"
    textColor: "#FFFFFF"
    typography: "{typography.label}"
    rounded: "{rounded.full}"
    padding: "0 24px"
    height: "56px"
  button-primary-monitor:
    backgroundColor: "{colors.monitor-primary}"
    textColor: "#FFFFFF"
    typography: "{typography.label}"
    rounded: "{rounded.full}"
    padding: "12px 28px"
  card-patient:
    backgroundColor: "{colors.patient-surface-container}"
    rounded: "{rounded.lg}"
    padding: "20px"
  card-monitor:
    backgroundColor: "#FFFFFF"
    rounded: "{rounded.xl}"
    padding: "24px"
  input-patient:
    backgroundColor: "{colors.patient-surface-container}"
    textColor: "{colors.patient-ink}"
    rounded: "{rounded.md}"
    padding: "12px 16px"
  input-monitor:
    backgroundColor: "{colors.monitor-surface-container}"
    textColor: "{colors.monitor-ink}"
    rounded: "{rounded.md}"
    padding: "12px 16px"
---

# Design System: MedBuddy

## 1. Overview

**Creative North Star: "The Daily Companion, Two Voices"**

MedBuddy lives in two places: a phone you open every morning, and a dashboard a worried family member checks before lunch. Same product, same brand DNA, two voices. The patient app speaks in **Petal**: warm pink-rose surfaces, generous rounded edges, small celebrations woven into a daily ritual. The monitor dashboard speaks in **Vesper**: an evening-toned violet, observant, calmer, more whitespace, more deference to the data. The two surfaces should feel like the same person greeting you in the morning vs. checking in at 9pm.

This is medical software that refuses to feel medical. No sterile blue-on-white, no clinical forms, no compliance language. But it also isn't a habit-tracker mascot screaming about your streak: stakes are real, a missed dose is information not a UI moment. The pink is the warmth around the verification flow, not on top of it. The violet is the calm around the dashboard, not a chrome.

**Key Characteristics:**
- Two distinct palettes (pink Petal for patient, violet Vesper for monitor) sharing the same shape language, type system, and motion grammar
- Generous radii (24-32px on cards, full radius on primary buttons) signal warmth and approachability
- Flat by default. Color and type carry hierarchy. Shadows are reserved for press/hover state and the primary CTA only
- Plus Jakarta Sans for display weight, Be Vietnam Pro for reading. Tight display tracking, comfortable body line-height
- Color is never the only signal; verified/pending/missed always pair with an icon and word

## 2. Colors: The Petal and Vesper Palettes

Two parallel palettes, one shared sage green that means "verified" in both. The patient pink is committed, carrying 30-50% of any patient screen surface via the gradient CTA and accent moments. The monitor violet is restrained, primary on action and identity (header, primary button, brand mark) but not on the data canvas itself, which stays a near-white lavender wash so the calendar and photos read first.

### Primary
- **Petal Rose** (`#E04D8C`, `oklch(0.62 0.18 350)`): The patient identity color. Primary CTAs (gradient blush → rose), active tab indicators, the streak hero number's accent, key icons. The pink that earns the "cutesy" without becoming Barbie.
- **Vesper Violet** (`#6D3FD3`, `oklch(0.55 0.22 295)`): The monitor identity color. Header brand bar, primary "Link patient" button, dashboard accent. A true violet (hue ~295), not blue-leaning, not magenta-leaning. Evening before night.

### Secondary
- **Verified Sage** (`#6CB57E` patient / `#4FA86A` monitor): Used exclusively for the verified state. Same hue family in both surfaces because "verified" must read identically across them. The patient variant is slightly lighter to coexist with pink; the monitor variant is denser to read against lavender-white.

### Tertiary (accent)
- **Blush** (`#FFB6CB`): Patient gradient endpoint, soft pink for celebratory backgrounds, light chip fills. Never on text against white.
- **Lavender** (`#9B7AE8`): Monitor gradient endpoint, hover state for monitor primary CTA, soft chip fills. Never on text against white.

### Neutral
- **Petal White** (`#FFF7FA`): Patient default surface. A pink-tinted white, chroma 0.005 toward primary. Never `#FFFFFF`.
- **Petal Cushion** (`#F7E9EE`): Patient card / container surface. Soft blush.
- **Petal Ink** (`#2A171F`): Patient text on light. Deep plum-near-black with brand hue, chroma 0.02. Never `#000000`.
- **Petal Outline** (`#E8CFD8`): Patient dividers, input strokes.
- **Vesper Mist** (`#FBF7FE`): Monitor default surface. Lavender-tinted white. The data canvas.
- **Vesper Stone** (`#EEE7F7`): Monitor card / container, chart cursor fill.
- **Vesper Ink** (`#1C1626`): Monitor text. Deep violet-near-black.
- **Vesper Outline** (`#D8CCE9`): Monitor dividers, input strokes.

### Status
- **Petal Alert** (`#C6294B`): Patient errors. Rose-tinted red (not Vesper crimson) so it sits in the patient palette without clashing.
- **Vesper Alert** (`#BA1A1A`): Monitor danger / missed-dose banner. A true red, never violet, so alerts cannot be mistaken for brand color.
- **Amber** (`#E8B23A`): Warning / "pending" in both. Hue ~75. Neutral to both palettes.

### Named Rules

**The Two-Voice Rule.** Patient screens never use Vesper Violet; monitor screens never use Petal Rose. The shared brand sits in shape, type, and motion, not in color. If you find yourself reaching for the other palette's hue, you've crossed registers.

**The Red-Is-Red Rule.** Alert reds (`#C6294B` patient, `#BA1A1A` monitor) are not brand colors. They are reserved for missed doses, validation failures, and destructive-action confirmations. Never as a decorative accent, never on a CTA, never on a chart bar that isn't reporting an alert.

**The Sage-Is-Verified Rule.** Green appears only when a dose is verified. Not for "good," not for "OK," not for "active." The pairing `verified ↔ sage` is non-negotiable across both surfaces.

## 3. Typography

**Display Font:** Plus Jakarta Sans (system-ui, sans-serif fallback)
**Body Font:** Be Vietnam Pro (system-ui, sans-serif fallback)

**Character:** A confident, slightly geometric display face paired with a humanist body face. Plus Jakarta Sans at heavy weights (800, 900) carries the brand swagger; Be Vietnam Pro at 400/600 reads comfortably in microcopy and longform. Display sits on tight negative tracking (-1.5px to -3px); body breathes at 1.45-1.5 line-height. The pairing reads cheerful but not childish, friendly but not corporate.

### Hierarchy
- **Streak Number** (PJS 900, 88px, -3px track, 1.0 line): The patient app's signature flex moment. Used exactly once per screen, only on the streak hero. Never on monitor.
- **Display** (PJS 800, 56px / clamp on web, -1.5px track, 1.05 line): Onboarding hero copy, landing-page hero. Once per page.
- **Headline** (PJS 700, 28px, -0.3px track): Screen titles. "Profile", "History", "Today".
- **Title** (PJS 600, 18px): Card headers, section labels.
- **Body** (Be Vietnam Pro 400, 16px, 1.5 line): Paragraphs, descriptions, longform. Cap reading width at 65-75ch on dashboard, full container width on mobile.
- **Body Small** (Be Vietnam Pro 400, 14px, 1.45 line): Secondary descriptions, helper text, captions.
- **Label** (Be Vietnam Pro 600, 14px, 0.3px track): Form labels, status pills, button text on secondary buttons.

### Named Rules

**The One-Display Rule.** A screen carries at most one display-tier element. If you have two competing 28+ pixel headlines, the layout is fighting itself. Make one bigger or demote the other to title.

**The No-Gradient-Text Rule.** Plus Jakarta Sans never gets a gradient fill via `background-clip: text`. Color emphasis is solid Petal Rose, Vesper Violet, or ink. Weight and size carry hierarchy. Gradient text is a 2018 SaaS reflex and we don't.

## 4. Elevation

**Flat by default.** Cards are flat (`cardElevation: 0` in `app_dimensions.dart`); the dashboard's white cards on lavender-mist surface get their separation from the background tone shift, not a shadow. Depth is conveyed by tonal contrast (surface vs. surface-container) and by whitespace.

Shadows appear in exactly two places:
1. **Primary CTA shadow.** Patient `PrimaryButton` carries a soft brand-tinted shadow at rest (`0 8px 18px rgba(224, 77, 140, 0.30)` on patient; equivalent for monitor). This is functional: it elevates the action above the page.
2. **Welcome-card hero shadow.** The landing-page hero card on dashboard (`shadow-2xl` Tailwind, ~`0 25px 50px -12px rgba(0,0,0,0.25)`) sells the first impression. Inside the app, never.

### Named Rules

**The Press-Don't-Hover Rule.** Cards don't lift on hover. Buttons don't lift on hover. Hover is a 200ms tint shift or a subtle scale (0.98 → 1.0 on press). The phone has no hover state at all; designing for hover-lift is desktop muscle memory leaking into mobile.

## 5. Components

### Buttons
- **Shape:** Full radius (9999px). Always pill-shaped. No square buttons, no chamfered corners, no edge variants.
- **Primary (Patient):** Coral-blush gradient (`#FFB6CB → #E04D8C`, 135deg). 56px tall, 24px horizontal padding, 16px PJS 700 white label with 0.3px tracking. Shadow `0 8px 18px rgba(224, 77, 140, 0.30)`. Disabled state: outline color fill, no shadow.
- **Primary (Monitor):** Same gradient grammar with violet pair (`#9B7AE8 → #6D3FD3`). Slightly smaller on web (typical button-y proportions, 12px vertical padding × 28px horizontal).
- **Secondary / Outlined:** 2px primary border, primary text, transparent fill. Used for "Sign in instead" / "Sign out" / sign-up CTAs on landing.
- **Tertiary / Text-link:** Inline text in primary color, no border, no fill. Used for inline microcopy actions ("Already have an account?").

### Cards
- **Patient cards:** `#F7E9EE` (Petal Cushion) background, 24px radius (`radiusLg`), 20px internal padding. No shadow, no border. Differentiated from page background by the 0.012 chroma shift.
- **Monitor cards:** `#FFFFFF` background on `#FBF7FE` page (Vesper Mist). 32px radius (`radiusXl`, Tailwind `rounded-4xl`). 24px internal padding. The white-on-lavender contrast is the entire elevation strategy on dashboard.
- **Nested cards are forbidden.** A card inside a card is always wrong. Inline rows or a section divider does the job.

### Inputs
- **Style:** Surface-container fill (`#F7E9EE` patient, `#EEE7F7` monitor), 16px radius (`radiusMd`), no border at rest, 1px outline color stroke on focus.
- **Focus:** Border shifts to primary color (Petal Rose / Vesper Violet). No box-shadow glow.
- **Placeholder:** Body Small at 60% ink opacity.
- **Mono-input** (link code paste): Monospace family inside the same input shape. Used on the monitor's "Link a patient" form.

### Status Chips
- **Verified:** Sage background (`#D8EFDB` light fill), sage 600 text, checkmark icon. Pill radius.
- **Pending:** Amber background, deep amber text, clock icon.
- **Missed:** Petal Alert / Vesper Alert background, white text, alert icon. The strongest contrast in the system because the read needs to be unmissable.

### Navigation
- **Mobile bottom nav:** 3 destinations (Home / History / Profile), pill-shaped active indicator behind icon, label below. Active = primary fill on pill, ink label.
- **Dashboard top nav:** Brand mark + patient name on left, "Sign out" inline on right. No middle nav; the dashboard is a single page.

### Signature: Streak Hero (Patient)
The patient home's marquee element. Coral-blush gradient background fills a full-width card with `radiusXl` corners. White 88px PJS 900 streak number left-aligned, current "day X" label below in label-small white-90%. No decoration, no confetti, no "🔥". The number carries the celebration on its own. When the streak breaks, the gradient softens to surface-container and the number renders in ink at 1/3 the size. No mascot tears, no shame copy.

## 6. Do's and Don'ts

### Do:
- **Do** use Petal Rose (`#E04D8C`) only on patient surfaces and Vesper Violet (`#6D3FD3`) only on monitor surfaces. The Two-Voice Rule is load-bearing.
- **Do** pair every status color with an icon and a word. Color-blindness safety is a hard constraint, not an aesthetic option.
- **Do** keep the verified-sage hue identical in role (verified state) across both surfaces.
- **Do** reach for tonal contrast first when separating layers. Save shadow for the primary CTA and the dashboard hero card.
- **Do** cap dashboard body line length at 65-75ch. The mobile app gets full container width because phone columns are narrow already.
- **Do** treat verification as a non-decorative flow. Confidence values render honestly, capture state is plain, failure is information.
- **Do** use the streak hero gradient at full saturation. The patient app earns its "cheerful, encouraging, human" personality in this one moment per screen.

### Don't:
- **Don't** look like a clinical portal. No white-on-blue, no grids of forms, no "Submit Medical Information" buttons, no MyChart aesthetic.
- **Don't** look pharma-corporate. No stock photos of smiling models, no navy-and-gold, no serif headlines pretending to be a legacy brand.
- **Don't** gamify into anxiety. No mascots that look sad. No streak-loss confetti, no "Don't break your 47-day streak!" red alerts. A broken streak resets quietly.
- **Don't** look like a generic SaaS dashboard. No big-number-hero template, no identical card grids, no Recharts defaults. The monitor dashboard answers one question in three seconds, not twelve metrics in twelve cards.
- **Don't** use side-stripe borders (`border-left: 4px`) as a colored accent on any card, callout, or alert. Use full borders, background tints, or leading icons.
- **Don't** use gradient text via `background-clip: text`. Emphasis is solid color + weight.
- **Don't** use glassmorphism. No blur-card on translucent background. Petal Rose and Vesper Violet sit on opaque tinted whites.
- **Don't** use `#000000` or `#FFFFFF` anywhere. Every neutral tints toward the matching surface's hue (chroma 0.005-0.012).
- **Don't** add hover-lift on cards or buttons. Mobile has no hover; desktop's primary action is the press tint, not vertical motion.
- **Don't** nest cards. A card inside a card is always a wrong answer.
- **Don't** use compliance-language microcopy. "Time for your morning dose" not "Patient ID 4729 has a scheduled administration." Sixth-grade reading level. Contractions. Second person.
