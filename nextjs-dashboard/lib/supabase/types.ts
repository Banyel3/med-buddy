export type ComplianceStatus = 'pending' | 'verified' | 'late' | 'missed';

export interface ComplianceLog {
  id: string;
  medication_id: string;
  user_id: string;
  date: string;
  status: ComplianceStatus;
  image_url: string | null;
  verified_at: string | null;
  face_confidence: number | null;
  pill_confidence: number | null;
  /** Set when the patient pressed "I can't take it now" on the dose alarm. */
  skipped_at: string | null;
}

export interface Streak {
  id: string;
  user_id: string;
  current_streak: number;
  longest_streak: number;
  last_verified_date: string | null;
  updated_at: string;
}

export interface MedUser {
  id: string;
  name: string;
  role: 'patient' | 'monitor';
  timezone: string;
}
