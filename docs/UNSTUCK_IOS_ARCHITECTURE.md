# Unstuck iOS Architecture

## Overview

Unstuck iOS is a SwiftUI app backed by Supabase Auth and Supabase Postgres. The app uses environment object stores for app-wide state and keeps most feature logic in small model/store/service files.

The current architecture is intentionally simple for the POC:

- SwiftUI views own UI state.
- Stores expose app state through `ObservableObject`.
- Supabase service calls are async.
- Supabase is the source of truth for authenticated profiles and sessions.
- UserDefaults remains for local appearance fallback, local session cache, notification settings, and local streak state.

## Current File Structure Overview

### App Root

- `Unstuck_V1App.swift`
  - Creates root stores.
  - Injects environment objects.
  - Restores auth state.
  - Loads sessions and profile after auth.
  - Applies preferred appearance.
  - Clears user-scoped state on sign-out.

- `Supabase.swift`
  - Defines the shared Supabase client.

### Services

- `AuthService.swift`
  - Supabase Auth sign-in, sign-out, and session restore.

- `SessionSyncService.swift`
  - Saves sessions to Supabase.
  - Loads sessions from Supabase.
  - Converts Supabase records into local `Session` models.
  - Tolerates multiple `answers_json` shapes.

- `NotificationManager.swift`
  - Requests notification permission.
  - Schedules/cancels daily reminder notifications.

### Data Stores

- `SessionStore.swift`
  - Publishes loaded sessions.
  - Saves local session copies.
  - Calls `SessionSyncService` for Supabase sync.

- `ProfileStore.swift`
  - Publishes authenticated user profile.
  - Loads profile from `profiles`.
  - Updates `display_name`.
  - Updates `preferred_theme`.

- `AppearanceStore.swift`
  - Publishes selected `AppAppearance`.
  - Applies Supabase profile theme.
  - Resets to `.system` on sign-out.
  - Keeps local fallback in UserDefaults.

- `StreakStore.swift`
  - Tracks local streak state.
  - Scopes local data by authenticated user id.

- `SampleForms.swift`
  - Defines Short Check-In and Main Form form definitions.

### Models

- `Answer.swift`
- `Session.swift`
- `FormDefinition.swift`
- `FormQuestion.swift`
- `Profile.swift`
- `StreakState.swift`
- `SupabaseSessionRecord.swift`
- `AppAppearance.swift`

### Views

- `Views/Auth/AuthView.swift`
- `Views/Home/HomeView.swift`
- `Views/Home/ActionCard.swift`
- `Views/CheckIn/CheckInFlowView.swift`
- `Views/CheckIn/SessionSummaryView.swift`
- `Views/Sessions/PastSessionsView.swift`
- `Views/Sessions/SessionRowView.swift`
- `Views/Sessions/SessionDetailView.swift`
- `Views/Insights/InsightsView.swift`
- `Views/Settings/SettingsView.swift`
- `Views/Settings/NotificationSettingsView.swift`
- `Views/Shared/AppCard.swift`
- `Views/Shared/PrimaryButton.swift`
- `Views/Shared/SecondaryButton.swift`
- `Views/Shared/SectionHeader.swift`

## App Startup Flow

1. `Unstuck_V1App` creates:
   - `AuthService`
   - `SessionStore`
   - `StreakStore`
   - `AppearanceStore`
   - `ProfileStore`

2. `AuthService` attempts to restore a Supabase Auth session.

3. Root UI state:
   - Loading: show `ProgressView`.
   - Authenticated: show `HomeView`.
   - Not authenticated: show `AuthView`.

4. When `authService.currentUser?.id` changes:
   - Configure `StreakStore` for the active user.
   - Clear in-memory sessions.
   - Load sessions from Supabase.
   - Load profile from Supabase.
   - Apply `profile.preferred_theme` through `AppearanceStore`.

5. On sign-out:
   - Clear in-memory sessions.
   - Clear profile state.
   - Reset appearance to `.system`.
   - Clear user-scoped streak state.

## Auth Flow

1. User enters email and password in `AuthView`.
2. `AuthService.signIn(email:password:)` calls Supabase Auth.
3. On success:
   - `currentUser` is set.
   - `isAuthenticated` becomes `true`.
4. App root observes the user id change and loads user-scoped data.
5. On sign-out:
   - `AuthService.signOut()` calls Supabase Auth.
   - `currentUser` is cleared.
   - App root clears user-scoped state.

## Profile Loading Flow

1. App root receives authenticated user id.
2. `ProfileStore.loadProfile(userId:)` selects from `profiles` where `id == userId`.
3. `ProfileStore.profile` is updated.
4. App root applies `profile.preferredTheme` to `AppearanceStore`.
5. `SettingsView` displays:
   - Auth email
   - Display name
   - Appearance picker

## Theme Preference Flow

### Load

1. User signs in or session restores.
2. App root loads `profiles`.
3. `profiles.preferred_theme` is converted to `AppAppearance`.
4. `AppearanceStore` updates the root `.preferredColorScheme`.

### Edit on iOS

1. User changes the Settings appearance picker.
2. `AppearanceStore.appearance` updates immediately.
3. `ProfileStore.updatePreferredTheme(userId:appearance:)` updates `profiles.preferred_theme`.
4. Web can read the same profile value.

### Sign-Out Safety

On sign-out, iOS resets appearance to `.system` so User A's theme does not leak visually into User B's session.

## Session Sync Flow

### Save

1. User completes Short Check-In or Main Form.
2. `CheckInFlowView` navigates to `SessionSummaryView`.
3. User taps Save Session.
4. `SessionStore.saveSession(form:answers:userId:)` creates a local `Session`.
5. If authenticated, `SessionSyncService.saveSessionToSupabase(...)` inserts into `sessions`.
6. `StreakStore.recordCompletion()` updates local streak state.

### Load

1. App root loads sessions after auth.
2. `PastSessionsView` also refreshes sessions when it appears.
3. Pull-to-refresh in Past Sessions calls `SessionStore.loadSessionsFromSupabase()`.
4. `SessionSyncService.loadSessionsFromSupabase()` selects rows from `sessions`.
5. RLS ensures only the authenticated user's rows are returned.
6. Rows are converted into local `Session` models for Past Sessions, Session Detail, and Insights.

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

The web app may use normalized or alternate shapes, including:

- Array of objects with prompt/answer fields
- Dictionary keyed by question id
- Existing iOS dictionary format

iOS currently tolerates these shapes during decode. This is a compatibility layer, not the final architecture.

Backlog reference:

- `UN-ARCH-001 Standardize session answer storage`

## Future Architecture Backlog

- `UN-ARCH-001 Standardize session answer storage`
  - Define one canonical `answers_json` format used by web and iOS.

- `UN-ARCH-002 Shared form definition system`
  - Avoid drift between iOS and web form definitions.

- `UN-ARCH-003 Canonical form engine design`
  - Define a shared model for form rendering, validation, summaries, and answer serialization.

- `UN-PROFILE-001 Move streak/completed_today to backend`
  - Store streak and completed-today state in Supabase so it follows the user across devices.
