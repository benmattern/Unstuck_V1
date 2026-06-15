# Unstuck iOS Recovery Prompt

Use this prompt to catch up another AI or coding session on the current Unstuck iOS app.

## Project

Unstuck iOS is a SwiftUI/Xcode app backed by Supabase. The iOS app is currently the primary platform. A React/TypeScript/Vite web app shares the same Supabase backend and should eventually reach feature parity.

## Current Stack

- Swift
- SwiftUI
- Xcode
- Supabase Swift

## Current Features

- Authentication
- Profile sync
- User-scoped theme preferences
- Short Check-In
- Main Form
- Session history
- Session detail
- Session sync with Supabase
- Insights
- Notifications
- Settings
- Streak tracking

## Backend Integration

Supabase is configured with:

- `auth.users`
- `profiles`
- `sessions`
- Row Level Security

Current data flow:

```text
Auth
↓
Profiles
↓
Sessions
```

Supabase Auth provides the user id. The app then loads the matching profile row and user-owned session rows. RLS is expected to enforce User A/User B isolation.

## Tables

### `auth.users`

Supabase Auth owns authenticated user identity. iOS reads the current user from the Supabase Auth session.

### `profiles`

Fields:

- `id uuid primary key`
- `display_name text`
- `preferred_theme text`
- `onboarding_completed boolean`
- `created_at timestamptz`
- `updated_at timestamptz`

iOS uses `profiles` for:

- Display name sync
- Preferred theme sync
- User-scoped settings

### `sessions`

Fields:

- `id uuid primary key`
- `user_id uuid references auth.users(id)`
- `form_type text`
- `answers_json jsonb`
- `created_at timestamptz`

iOS uses `sessions` for:

- Saving completed Short Check-In sessions
- Saving completed Main Form sessions
- Loading authenticated session history
- Session detail
- Insights calculations

## Important Current Files

### App Root

- `Unstuck V1/Unstuck V1/Unstuck_V1App.swift`
  - Creates root stores.
  - Injects environment objects.
  - Routes between loading, auth, and home.
  - Loads sessions and profile after auth.
  - Applies profile theme.
  - Clears user-scoped state on sign-out.

- `Unstuck V1/Unstuck V1/Supabase.swift`
  - Shared Supabase client.

### Auth/Profile/Sync

- `Services/AuthService.swift`
  - Supabase Auth sign-in, sign-out, restore session.

- `Data/ProfileStore.swift`
  - Loads profile.
  - Updates display name.
  - Updates preferred theme.

- `Data/SessionStore.swift`
  - Publishes sessions.
  - Saves local session copy.
  - Calls Supabase session sync service.

- `Services/SessionSyncService.swift`
  - Saves sessions to Supabase.
  - Loads sessions from Supabase.
  - Converts flexible `answers_json` shapes into local `Session` models.

### Profile System

- `Models/Profile.swift`
  - Maps `profiles` with snake_case coding keys.

- `Data/ProfileStore.swift`
  - Owns profile load/update state.

- `Data/AppearanceStore.swift`
  - Applies `profiles.preferred_theme` locally.
  - Resets to `.system` on sign-out.
  - Keeps local fallback.

- `Theme/AppAppearance.swift`
  - Defines `system`, `light`, and `dark`.

- `Views/Settings/SettingsView.swift`
  - Shows account email.
  - Edits display name.
  - Updates preferred theme.
  - Handles sign-out entry point.

### Forms/Sessions

- `Data/SampleForms.swift`
  - Short Check-In and Main Form definitions.

- `Views/CheckIn/CheckInFlowView.swift`
  - One-question-at-a-time form flow.

- `Views/CheckIn/SessionSummaryView.swift`
  - Review answers before save.

- `Views/Sessions/PastSessionsView.swift`
  - Supabase-backed session history.
  - Refreshes on appear and pull-to-refresh.

- `Views/Sessions/SessionDetailView.swift`
  - Displays saved questions and answers.

### Other App Areas

- `Views/Home/HomeView.swift`
- `Views/Home/ActionCard.swift`
- `Views/Insights/InsightsView.swift`
- `Views/Settings/NotificationSettingsView.swift`
- `Services/NotificationManager.swift`
- `Data/StreakStore.swift`
- `Views/Shared/*`

## Current File/Folder Structure Overview

```text
Unstuck V1/
  Unstuck V1/
    Data/
      AppearanceStore.swift
      ProfileStore.swift
      SampleForms.swift
      SessionStore.swift
      StreakStore.swift
    Models/
      Answer.swift
      FormDefinition.swift
      FormQuestion.swift
      Profile.swift
      Session.swift
      StreakState.swift
      SupabaseSessionRecord.swift
    Services/
      AuthService.swift
      NotificationManager.swift
      SessionSyncService.swift
    Theme/
      AppAppearance.swift
      AppTheme.swift
    Views/
      Auth/
      CheckIn/
      Home/
      Insights/
      Sessions/
      Settings/
      Shared/
    ContentView.swift
    Supabase.swift
    Unstuck_V1App.swift
```

## Current App Startup Flow

1. App launches.
2. `AuthService` attempts Supabase Auth session restore.
3. Root view shows loading while restore is in progress.
4. If unauthenticated, root shows `AuthView`.
5. If authenticated, root shows `HomeView`.
6. App root handles the current user id:
   - Configure `StreakStore`.
   - Clear in-memory sessions.
   - Load Supabase sessions.
   - Load Supabase profile.
   - Apply `profile.preferred_theme`.

## Auth Flow

1. User signs in with email/password.
2. `AuthService.signIn(email:password:)` calls Supabase Auth.
3. Supabase returns a session.
4. `AuthService.currentUser` is set.
5. App root loads user-scoped profile and sessions.

On sign-out:

1. `AuthService.signOut()` calls Supabase Auth.
2. `currentUser` clears.
3. In-memory sessions clear.
4. Profile state clears.
5. Appearance resets to `.system`.
6. Streak store de-scopes from the previous user.

## Profile Loading Flow

1. Auth user id becomes available.
2. `ProfileStore.loadProfile(userId:)` selects from `profiles`.
3. `ProfileStore.profile` publishes the profile.
4. `AppearanceStore.applyProfileTheme(...)` applies `preferred_theme`.
5. Settings displays email, display name, and appearance.

Display name sync:

1. User edits display name in Settings.
2. `ProfileStore.updateDisplayName(userId:displayName:)` updates `profiles.display_name`.

Preferred theme sync:

1. User changes appearance in Settings.
2. `AppearanceStore` updates immediately.
3. `ProfileStore.updatePreferredTheme(userId:appearance:)` updates `profiles.preferred_theme`.

## Session Synchronization Flow

1. User completes Short Check-In or Main Form.
2. `SessionSummaryView` displays answers before save.
3. Save creates a local session.
4. `SessionSyncService` inserts the session into Supabase `sessions`.
5. `PastSessionsView` refreshes from Supabase on appear and pull-to-refresh.
6. `SessionSyncService` converts rows into local `Session` models.
7. Session history, detail, and insights read from `SessionStore.sessions`.

## Known Technical Debt

### UN-ARCH-001

Standardize session answer storage.

Current mismatch:

- iOS writes `answers_json` as a dictionary keyed by question id.
- Web uses a normalization layer and may handle array/object forms.
- iOS currently tolerates multiple shapes in `SessionSyncService`.

### UN-ARCH-002

Shared form definition system.

Form definitions currently live locally in iOS and separately in web. The product needs a shared definition source to prevent drift.

### UN-ARCH-003

Canonical form engine design.

The product needs one canonical design for form rendering, validation, answer summaries, and answer serialization.

### UN-PROFILE-001

Move streak/completed_today from local storage to backend.

Current streak state is local and user-scoped. It should eventually live in Supabase so it follows users across iOS and web.

## Constraints For Future Work

- Do not modify Supabase schema unless explicitly requested.
- Do not modify RLS unless explicitly requested.
- Do not edit `.pbxproj` directly while Xcode is open.
- Prefer Xcode tools for project reads/writes/builds.
- Keep the POC simple.
- Preserve notifications.
- Preserve User A/User B isolation.
- Keep `answers_json` for the POC until `UN-ARCH-001` is addressed.

## Recovery Guidance

When resuming implementation:

1. Inspect current files before editing.
2. Keep changes narrowly scoped to the requested task.
3. If adding environment object requirements, update previews.
4. If touching profile/session sync, verify sign-in, sign-out, User A/User B isolation, and web/iOS consistency.
5. Build with Xcode after app source changes.
