# Unstuck iOS Status

## Current Stack

- Swift
- SwiftUI
- Xcode
- Supabase Swift
- Supabase Auth
- Supabase Postgres with RLS

## Current Product State

Unstuck iOS is the primary native client for the Unstuck POC. The app supports authenticated users, local form flows, Supabase-backed session sync, profile sync, settings, reminders, and lightweight insights.

The current POC goal is to demonstrate:

- Multiple authenticated users
- User-specific data isolation through Supabase RLS
- iOS app session creation and history
- Web-created sessions appearing in iOS
- Shared Supabase backend between iOS and web
- Scheduled daily reminders on iOS

## Current Features

- Auth
  - Supabase email/password sign-in
  - Sign-out
  - Session restore on app startup

- Profile sync
  - Loads authenticated user profile from `profiles`
  - Displays account email
  - Displays and edits `display_name`

- User-scoped theme preferences
  - Supports `system`, `light`, and `dark`
  - Loads `profiles.preferred_theme`
  - Updates `profiles.preferred_theme` from iOS Settings
  - Resets to `.system` on sign-out to avoid theme leakage between users

- Forms
  - Short Check-In
  - Main Form
  - One-question-at-a-time flow
  - Session summary before save

- Sessions
  - Saves completed sessions locally and to Supabase
  - Loads authenticated user sessions from Supabase
  - Past Sessions list
  - Pull-to-refresh on Past Sessions
  - Session detail view

- Insights
  - Total sessions
  - Short Check-Ins completed
  - Main Forms completed
  - Most recent session date
  - Most common blocker

- Notifications
  - Native daily reminder scheduling
  - Permission request
  - Reminder cancellation

- Settings
  - Account display
  - Display name editing
  - Appearance picker
  - Notification settings link
  - Local session deletion
  - Local streak reset
  - Sign-out

- Streak tracking
  - Local per-user streak state
  - UserDefaults key is scoped by authenticated user id
  - Not yet stored in Supabase

## Backend Integration

### Supabase Auth

iOS uses Supabase Auth for email/password authentication. `AuthService` restores an existing local Supabase session at startup and publishes the authenticated user state.

### `profiles`

Current profile fields used by iOS:

- `id`
- `display_name`
- `preferred_theme`
- `onboarding_completed`
- `created_at`
- `updated_at`

iOS loads the authenticated user profile after auth restore/sign-in. Settings can update `display_name` and `preferred_theme`.

### `sessions`

Current sessions table:

- `id`
- `user_id`
- `form_type`
- `answers_json`
- `created_at`

iOS inserts completed sessions into `sessions` and loads the authenticated user's rows from Supabase. RLS is expected to enforce user isolation.

## Known Architecture Notes

### Answer Storage Mismatch

Current iOS save format stores `answers_json` as a dictionary keyed by question id. Each value contains:

- `question_id`
- `question_prompt`
- `answer_value`

The web app may produce or normalize different answer shapes, including arrays of answer objects or dictionary forms. iOS currently has a tolerant decoder in `SessionSyncService` so web-created sessions can display in Past Sessions.

This should be standardized under:

- `UN-ARCH-001 Standardize session answer storage`

## Future Backlog References

- `UN-ARCH-001 Standardize session answer storage`
- `UN-ARCH-002 Shared form definition system`
- `UN-ARCH-003 Canonical form engine design`
- `UN-PROFILE-001 Move streak/completed_today to backend`

## Build Status

The project has been building successfully after the latest profile, theme, and Supabase session sync changes.
