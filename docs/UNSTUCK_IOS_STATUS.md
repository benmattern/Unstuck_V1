# Unstuck iOS Status

## Current Stack

- Swift
- SwiftUI
- Xcode
- Supabase Swift

## Current State

Unstuck iOS is the primary native client for the current Unstuck POC. It uses Supabase Auth for sign-in, Supabase `profiles` for user profile/settings sync, and Supabase `sessions` for authenticated session history.

The current data flow is:

```text
Auth
↓
Profiles
↓
Sessions
```

Authenticated identity comes from Supabase Auth. Profile data and user-scoped settings are loaded after auth. Session history is loaded and saved for the authenticated user.

## Current Features

- Authentication
  - Email/password sign-in through Supabase Auth
  - Auth session restore on app startup
  - Sign-out

- Profile sync
  - Loads authenticated user profile from `profiles`
  - Shows account email from Supabase Auth
  - Displays and edits `display_name`

- User-scoped theme preferences
  - Supports `system`, `light`, and `dark`
  - Loads `profiles.preferred_theme`
  - Updates `profiles.preferred_theme` from iOS Settings
  - Resets to `.system` on sign-out to prevent User A theme leaking to User B

- Short Check-In
  - Uses the shared local form architecture
  - One-question-at-a-time SwiftUI flow
  - Summary screen before save

- Main Form
  - Uses the same form flow as Short Check-In
  - Saves to the same session pipeline

- Session history
  - Loads authenticated user sessions from Supabase
  - Refreshes when Past Sessions appears
  - Supports pull-to-refresh

- Session detail
  - Displays saved questions and answers for a selected session

- Session sync with Supabase
  - Saves completed forms to `sessions`
  - Loads session rows from `sessions`
  - Converts Supabase rows into local `Session` models

- Insights
  - Total sessions
  - Short Check-Ins completed
  - Main Forms completed
  - Most recent session date
  - Most common blocker

- Notifications
  - Native daily reminder permission request
  - Daily reminder scheduling
  - Reminder cancellation

- Settings
  - Account email
  - Display name editing
  - Appearance picker
  - Notification settings
  - Local data controls
  - Sign-out

- Streak tracking
  - Local user-scoped streak state
  - Stored in UserDefaults under user-specific keys
  - Not yet stored in Supabase

## Backend Integration

### `auth.users`

Supabase Auth owns user identity. iOS reads the authenticated user from the Supabase session and uses the auth user id as the owner key for profiles, sessions, and local user-scoped state.

### `profiles`

The `profiles` table stores account-level profile and preference data.

Fields used by iOS:

- `id`
- `display_name`
- `preferred_theme`
- `onboarding_completed`
- `created_at`
- `updated_at`

iOS profile behavior:

- `ProfileStore.loadProfile(userId:)` loads the row matching the authenticated auth user id.
- `ProfileStore.updateDisplayName(userId:displayName:)` updates `display_name`.
- `ProfileStore.updatePreferredTheme(userId:appearance:)` updates `preferred_theme`.
- `AppearanceStore` applies `preferred_theme` locally after profile load.

### `sessions`

The `sessions` table stores completed form sessions.

Fields used by iOS:

- `id`
- `user_id`
- `form_type`
- `answers_json`
- `created_at`

iOS session behavior:

- Inserts completed Short Check-In and Main Form sessions.
- Loads the authenticated user's sessions from Supabase.
- Uses Supabase RLS to keep User A and User B isolated.
- Keeps local UserDefaults as a limited fallback/cache, not the authenticated source of truth.

### Row Level Security

RLS is enabled for user-owned data. Expected behavior:

- User A can only load User A rows.
- User B can only load User B rows.
- iOS does not manually filter other users' data; it relies on Supabase Auth and RLS.

## Current Data Flow

```text
Supabase Auth session
↓
AuthService.currentUser
↓
ProfileStore.loadProfile(userId:)
↓
AppearanceStore.applyProfileTheme(...)
↓
SessionStore.loadSessionsFromSupabase()
↓
Home, Past Sessions, Session Detail, Insights
```

## Current App Startup Flow

1. `Unstuck_V1App` creates root stores:
   - `AuthService`
   - `SessionStore`
   - `StreakStore`
   - `AppearanceStore`
   - `ProfileStore`

2. `AuthService` attempts to restore the Supabase Auth session.

3. The root app view shows:
   - Loading state while auth is restoring
   - `AuthView` when unauthenticated
   - `HomeView` when authenticated

4. When the current auth user id changes:
   - `StreakStore` is configured for that user.
   - In-memory sessions are cleared.
   - Supabase sessions are loaded.
   - Supabase profile is loaded.
   - `profiles.preferred_theme` is applied.

5. On sign-out:
   - In-memory sessions are cleared.
   - Profile state is cleared.
   - Appearance resets to `.system`.
   - Local streak state is de-scoped from the previous user.

## Auth Flow

1. User enters email and password in `AuthView`.
2. `AuthService.signIn(email:password:)` calls Supabase Auth.
3. Supabase returns an authenticated session.
4. `AuthService.currentUser` is set.
5. App root observes the user id and loads profile/session data.
6. Sign-out clears authenticated state and user-scoped app state.

## Profile Loading Flow

1. Auth user id becomes available.
2. App root calls `ProfileStore.loadProfile(userId:)`.
3. `ProfileStore` selects the matching `profiles` row.
4. `SettingsView` displays account email and display name.
5. `AppearanceStore` applies `preferred_theme`.
6. Settings edits write profile changes back to Supabase.

## Session Synchronization Flow

1. User completes Short Check-In or Main Form.
2. `SessionSummaryView` shows answers before saving.
3. `SessionStore.saveSession(form:answers:userId:)` creates a local `Session`.
4. `SessionSyncService.saveSessionToSupabase(...)` inserts into `sessions`.
5. `PastSessionsView` refreshes from Supabase on appear and pull-to-refresh.
6. `SessionSyncService.loadSessionsFromSupabase()` converts rows into local `Session` models.
7. `PastSessionsView`, `SessionDetailView`, and `InsightsView` read from `SessionStore.sessions`.

## Current File/Folder Structure Overview

- `Data/`
  - `AppearanceStore.swift`
  - `ProfileStore.swift`
  - `SampleForms.swift`
  - `SessionStore.swift`
  - `StreakStore.swift`

- `Models/`
  - `Answer.swift`
  - `FormDefinition.swift`
  - `FormQuestion.swift`
  - `Profile.swift`
  - `Session.swift`
  - `StreakState.swift`
  - `SupabaseSessionRecord.swift`

- `Services/`
  - `AuthService.swift`
  - `NotificationManager.swift`
  - `SessionSyncService.swift`

- `Theme/`
  - `AppAppearance.swift`
  - `AppTheme.swift`

- `Views/`
  - `Auth/`
  - `CheckIn/`
  - `Home/`
  - `Insights/`
  - `Sessions/`
  - `Settings/`
  - `Shared/`

- Root files
  - `ContentView.swift`
  - `Supabase.swift`
  - `Unstuck_V1App.swift`

## Known Technical Debt

### UN-ARCH-001

Standardize session answer storage.

Current mismatch:

- iOS writes `answers_json` as a dictionary keyed by question id.
- Web has a normalization layer and may handle array/object shapes.
- iOS currently has tolerant decode logic in `SessionSyncService`.

### UN-ARCH-002

Shared form definition system.

Short Check-In and Main Form definitions should eventually be shared across iOS and web so copy, ids, question types, and options cannot drift.

### UN-ARCH-003

Canonical form engine design.

The app needs a canonical design for rendering forms, validating answers, summarizing sessions, and serializing answers across clients.

### UN-PROFILE-001

Move streak/completed_today from local storage to backend.

Current streak tracking is local and user-scoped. It should eventually move to Supabase so streak state follows the user across devices.
