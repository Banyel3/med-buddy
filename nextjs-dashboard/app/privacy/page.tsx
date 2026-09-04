import Link from 'next/link';

export const metadata = {
  title: 'Privacy Policy — MedBuddy',
};

export default function PrivacyPage() {
  return (
    <main className="min-h-screen bg-surface text-ink py-12">
      <div className="max-w-3xl mx-auto px-6 prose prose-stone">
        <Link href="/" className="text-sm text-primary">
          ← Back
        </Link>
        <h1>MedBuddy — Privacy Policy</h1>
        <p className="text-ink/70">Last updated: 2026-05-24</p>

        <h2>What we collect</h2>
        <ul>
          <li>
            <strong>Account data:</strong> email + display name + timezone +
            and which side of MedBuddy the account is on.
          </li>
          <li>
            <strong>Medication schedule:</strong> name, daily reminder time,
            and any notes you enter.
          </li>
          <li>
            <strong>Verification photos:</strong> still images captured at
            each dose. Stored in a private Supabase Storage bucket; only
            you and your linked monitor can view them via signed URLs.
            Auto-deleted after 30 days.
          </li>
          <li>
            <strong>Compliance history:</strong> date, status (verified /
            late / missed), AI confidence scores. Used to compute streaks
            and surface adherence to your monitor.
          </li>
          <li>
            <strong>Device push tokens:</strong> FCM token stored only so
            we can deliver miss alerts to your monitor&apos;s device.
          </li>
        </ul>

        <h2>What we do NOT collect</h2>
        <ul>
          <li>
            We do not upload camera frames to any third party for AI
            inference. Face + pill detection run entirely on-device
            (Google ML Kit + TensorFlow Lite YOLOv8). Only the final
            still you confirm is uploaded.
          </li>
          <li>
            We do not sell or share your data with advertisers,
            insurers, or any third party.
          </li>
          <li>
            The Android Accessibility Service used to lock your phone
            after a missed dose does not read content of other apps —
            it only listens for window-state changes to re-front
            MedBuddy.
          </li>
        </ul>

        <h2>Storage + retention</h2>
        <p>
          Verification photos auto-expire 30 days after upload. Account
          data, medication schedules, and compliance history persist
          until you delete your account. Email{' '}
          <a href="mailto:privacy@medbuddy.app">privacy@medbuddy.app</a>{' '}
          to request deletion.
        </p>

        <h2>Permissions</h2>
        <ul>
          <li>
            <strong>Camera:</strong> verify each dose with a face +
            pill check.
          </li>
          <li>
            <strong>Notifications:</strong> daily medication reminders.
          </li>
          <li>
            <strong>Accessibility Service (Android, optional):</strong>{' '}
            lock your phone after a missed dose until you verify. You
            can disable this in Settings → Accessibility at any time.
          </li>
          <li>
            <strong>Display over other apps (Android, optional):</strong>{' '}
            render the lock overlay above other apps.
          </li>
        </ul>

        <h2>Your rights</h2>
        <p>
          You can export your data, request deletion, or revoke any
          permission at any time. Contact{' '}
          <a href="mailto:privacy@medbuddy.app">privacy@medbuddy.app</a>.
        </p>

        <h2>Open source</h2>
        <p>
          MedBuddy uses on-device AI from{' '}
          <a href="https://github.com/seblful/pills-detection">
            seblful/pills-detection
          </a>{' '}
          (CC BY 4.0) and Google ML Kit (Apache 2.0). See the in-app
          Credits screen for the full list.
        </p>
      </div>
    </main>
  );
}
