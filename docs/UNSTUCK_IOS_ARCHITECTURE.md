# Unstuck iOS Architecture

## Architecture Summary

Unstuck iOS is a SwiftUI app using Supabase Swift for authentication, profile sync, and session sync. The app is organized around small stores and services:

- Stores publish UI-facing state.
- Services perform Supabase or platform-specific work.
- Views stay focused on SwiftUI layout and user interactions.
- Supabase is the source of truth for authenticated profile and session data.
- Local storage remains for fallback/cache, notification settings, and local streak state.

Current data flow:

```text
Auth
↓
Profiles
↓
Sessions
```

## Current Stack

- Swift
- SwiftUI
- Xcode
- Supabase Swift

## Backend Integration

### `auth.users`

Supabase Auth creates and owns users. iOS receives the authenticated user from Supabase Auth and uses that user id for profile and session operations.

Related iOS file:

- `Services/AuthService.swift`

### `profiles`

The `profiles` table stores profile data and user-scoped settings.

Used fields:

- `id`
- `display_name`
- `preferred_theme`
- `onboarding_completed`
- `created_at`
- `updated_at`

Related iOS files:

- `Models/Profile.swift`
- `Data/ProfileStore.swift`
- `Data/AppearanceStore.swift`
- `Theme/AppAppearance.swift`
- `Views/Settings/SettingsView.swift`

### `sessions`

The `sessions` table stores completed form sessions.

Used fields:

- `id`
- `user_id`
- `form_type`
- `answers_json`
- `created_at`

Related iOS files:

- `Models/Session.swift`
- `Models/Answer.swift`
- `Models/SupabaseSessionRecord.swift`
- `Data/SessionStore.swift`
- `Services/SessionSyncService.swift`

### Row Level Security

RLS protects user-owned rows. The iOS app expects Supabase to return only the authenticated user's `profiles` and `sessions` rows. The client does not implement cross-user filtering as a substitute for RLS.

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
    Assets.xcassets
    ContentView.swift
    Supabase.swift
    Unstuck_V1App.swift
```

## App Root

`Unstuck_V1App.swift` creates and injects these environment objects:

- `AuthService`
- `SessionStore`
- `StreakStore`
- `AppearanceStore`
- `ProfileStore`

The root app:

- Shows a loading state while auth restores.
- Shows `AuthView` when unauthenticated.
- Shows `HomeView` when authenticated.
- Applies `.preferredColorScheme(appearanceStore.appearance.colorScheme)`.
- Responds to auth user id changes.

## Current App Startup Flow

1. App starts.
2. `AuthService` attempts Supabase session restore.
3. Root UI waits while auth is loading.
4. If no session exists, `AuthView` is shown.
5. If a session exists, `HomeView` is shown.
6. App root handles the authenticated user id:
   - Configure `StreakStore`.
   - Clear in-memory sessions.
   - Load Supabase sessions.
   - Load Supabase profile.
   - Apply `profiles.preferred_theme`.

## Auth Flow

1. User enters credentials in `AuthView`.
2. `AuthService.signIn(email:password:)` calls Supabase Auth.
3. On success:
   - `currentUser` is set.
   - `isAuthenticated` becomes `true`.
4. `Unstuck_V1App` observes the user id change.
5. User-scoped profile, theme, streak, and session state are configured.

On sign-out:

1. `AuthService.signOut()` calls Supabase Auth.
2. `currentUser` is cleared.
3. Root app clears in-memory sessions.
4. `ProfileStore` is cleared.
5. `AppearanceStore` resets to `.system`.
6. `StreakStore` is configured with `nil`.

## Profile System

The profile system is built from:

- `profiles` table
- `Profile` model
- `ProfileStore`
- `AppearanceStore`
- `SettingsView`

### Profile Loading Flow

1. Auth user id becomes available.
2. `ProfileStore.loadProfile(userId:)` selects the matching `profiles` row.
3. `ProfileStore.profile` publishes the loaded profile.
4. App root applies `profile.preferredTheme` through `AppearanceStore`.
5. `SettingsView` displays email, display name, and theme selection.

### Display Name Sync

1. User edits display name in Settings.
2. `ProfileStore.updateDisplayName(userId:displayName:)` updates `profiles.display_name`.
3. `ProfileStore.profile` is refreshed from the update response.
4. The new display name remains user-scoped through the authenticated profile row.

### Preferred Theme Sync

1. User changes the Settings appearance picker.
2. `AppearanceStore.appearance` updates immediately.
3. `ProfileStore.updatePreferredTheme(userId:appearance:)` updates `profiles.preferred_theme`.
4. App root and Settings can later reload the same value from Supabase.
5. On sign-out, appearance resets to `.system` to prevent theme leakage.

## Session Synchronization Flow

### Save Flow

1. User completes Short Check-In or Main Form.
2. `CheckInFlowView` navigates to `SessionSummaryView`.
3. User taps Save Session.
4. `SessionStore.saveSession(form:answers:userId:)` creates a local `Session`.
5. `SessionSyncService.saveSessionToSupabase(userId:form:answers:)` inserts into `sessions`.
6. `StreakStore.recordCompletion()` updates local streak state.

### Load Flow

1. App root loads sessions after auth.
2. `PastSessionsView` refreshes sessions when it appears.
3. Pull-to-refresh also calls `SessionStore.loadSessionsFromSupabase()`.
4. `SessionSyncService.loadSessionsFromSupabase()` selects session rows ordered newest first.
5. Rows are converted into local `Session` models.
6. `PastSessionsView`, `SessionDetailView`, and `InsightsView` read from `SessionStore.sessions`.

## Form System

Current form definitions live in `SampleForms.swift`.

Current forms:

- Short Check-In
- Main Form

Current form model files:

- `FormDefinition.swift`
- `FormQuestion.swift`
- `Answer.swift`
- `Session.swift`

The form flow is native SwiftUI and renders one question at a time. Both forms use the same `CheckInFlowView` and save through the same session pipeline.

## Notifications

Notifications are managed by `NotificationManager`.

Current capabilities:

- Request notification permission
- Schedule one daily reminder
- Cancel Unstuck reminders

Notification settings are local and not currently synced through Supabase.

## Streak Tracking

Streak tracking is local and user-scoped.

Current behavior:

- `StreakStore.configureForUser(userId:)` selects the active local streak key.
- Signed-out state does not load another user's streak.
- `recordCompletion()` updates local streak state after a saved session.

Backend migration is tracked by:

- `UN-PROFILE-001 Move streak/completed_today from local storage to backend`

## Answer Storage Mismatch

iOS currently writes `answers_json` as a dictionary keyed by question id:

```json
{
  "main_blocker": {
    "question_id": "main_blocker",
    "question_prompt": "What is the main blocker?",
    "answer_value": "Low energy"
  }
}
```

The web app has a normalization layer and may handle alternate shapes:

- Array of objects with prompt/answer values
- Dictionary keyed by question id
- Existing iOS dictionary format

iOS currently uses tolerant decode logic in `SessionSyncService` so web-created sessions can display. This compatibility layer should be replaced by one canonical format.

## Known Technical Debt

### UN-ARCH-001

Standardize session answer storage.

### UN-ARCH-002

Shared form definition system.

### UN-ARCH-003

Canonical form engine design.

### UN-PROFILE-001

Move streak/completed_today from local storage to backend.
