import type { Timestamp } from 'firebase/firestore'

// Mirrors the Dart models in lib/models/. Keep field names in sync with
// each model's toMap()/fromFirestore().

export type MaterialCategory =
  | 'lessonPlan'
  | 'flashcard'
  | 'icebreaker'
  | 'worksheet'
  | 'digitalTool'
  | 'other'

export type TeachingLevel =
  | 'kinder'
  | 'primary'
  | 'secondary'
  | 'adults'
  | 'business'

export type JobStatus = 'active' | 'filled' | 'closed'

export type UserType = 'teacher' | 'institution' | 'admin'

export type BenefitCategory =
  | 'learningMaterials'
  | 'institutions'
  | 'lifestyle'
  | 'shopping'

export interface TeachingMaterial {
  id: string
  title: string
  description: string
  category: MaterialCategory
  suitableFor: TeachingLevel[]
  fileUrl?: string | null
  thumbnailUrl?: string | null
  uploadedBy: string
  uploaderName: string
  uploadedAt: Timestamp
  downloadCount: number
  tags: string[]
  institutionId?: string | null
  institutionName?: string | null
}

export interface JobPosting {
  id: string
  postedBy: string
  institutionName: string
  jobTitle: string
  description: string
  location: string
  shifts: string[]
  levels: TeachingLevel[]
  requiredCertifications: string[]
  hoursPerWeek?: number | null
  salaryRange?: string | null
  postedAt: Timestamp
  expiresAt?: Timestamp | null
  status: JobStatus
  applicationsCount: number
  viewsCount: number
}

export interface AppUser {
  uid: string
  email: string
  userType: UserType
  displayName: string
  photoUrl?: string | null
  createdAt: Timestamp
  isVerified: boolean
}

export interface Benefit {
  id: string
  sponsorName: string
  sponsorLogo: string
  title: string
  description: string
  discount: string
  category: BenefitCategory
  validUntil: Timestamp
  isActive: boolean
  termsAndConditions?: string | null
  websiteUrl?: string | null
}

export const MATERIAL_CATEGORY_LABELS: Record<MaterialCategory, string> = {
  lessonPlan: 'Lesson Plan',
  flashcard: 'Flashcard',
  icebreaker: 'Icebreaker',
  worksheet: 'Worksheet',
  digitalTool: 'Digital Tool',
  other: 'Other',
}

export const BENEFIT_CATEGORY_LABELS: Record<BenefitCategory, string> = {
  learningMaterials: 'Learning Materials',
  institutions: 'Institutions',
  lifestyle: 'Lifestyle',
  shopping: 'Shopping',
}
