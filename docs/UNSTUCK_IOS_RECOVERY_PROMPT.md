# Unstuck iOS Recovery Prompt

Use this prompt to catch up another AI or coding session.

## Project

Unstuck iOS is a SwiftUI/Xcode app backed by Supabase. The iOS app is the primary platform for the current POC. A React/TypeScript/Vite web app shares the same Supabase backend.

## Current Stack

- Swift
- SwiftUI
- Xcode
- Supabase Swift
- Supabase Auth
- Supabase Postgres with RLS

## Current POC Goal

Demonstrate:

1. Multiple authenticated users.
2. Shared Supabase backend.
3. iOS app and web app both reading/writing user data.
4. User-specific data isolation through RLS.
5. Scheduled notifications on iOS.

## Current Backend

Supabase project is configured with:

- Supabase Auth
- `profiles`
- `sessions`
- RLS policies for user-specific access

### `profiles`

Fields:

- `id uuid primary key`
- `display_name text`
- `preferred_theme text`
- `onboarding_completed boolean`
- `created_at timestamptz`
- `updated_at timestamptz`

iOS currently:

- Loads the authenticated user's profile.
- Edits `display_name`.
- Reads and writes `preferred_theme`.
- Supports `preferred_theme` values: `system`, `light`, `dark`.

### `sessions`

Fields:

- `id uuid primary key`
- `user_id uuid references auth.users(id)`
- `form_type text`
- `answers_json jsonb`
- `created_at timestamptz`

iOS currently:

- Saves completed sessions to Supabase.
- Loads authenticated user sessions from Supabase.
- Displays Past Sessions and Session Detail.
- Calculates Insights from loaded sessions.

## Current iOS Features

- Auth
- Profile sync
- User-scoped theme preferences
- Short Check-In
- Main Form
- Session Summary before save
- Session history
- Session detail
- Session sync with Supabase
- Insights
- Notifications
- Settings
- Streak tracking

## Important Current Files

### App Root

- `Unstuck V1/Unstuck V1/Unstuck_V1App.swift`
  - Creates and injects stores.
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

- `Services/SessionSyncService.swift`
  - Saves sessions to Supabase.
  - Loads sessions from Supabase.
  - Converts flexible `answers_json` shapes into local `Session` models.

- `Data/SessionStore.swift`
  - Publishes sessions.
  - Saves local copy.
  - Calls Supabase sync service.

### Theme/Streak

- `Theme/AppAppearance.swift`
  - `system`, `light`, `dark`.

- `Data/AppearanceStore.swift`
  - Applies profile theme.
  - Resets to `.system` on sign-out.
  - Keeps local fallback.

- `Data/StreakStore.swift`
  - Local user-scoped streak state.
  - Uses user-specific UserDefaults keys.

### Views

- `Views/Auth/AuthView.swift`
- `Views/Home/HomeView.swift`
- `Views/Home/ActionCard.swift`
- `Views/CheckIn/CheckInFlowView.swift`
- `Views/CheckIn/SessionSummaryView.swift`
- `Views/Sessions/PastSessionsView.swift`
- `Views/Sessions/SessionDetailView.swift`
- `Views/Insights/InsightsView.swift`
- `Views/Settings/SettingsView.swift`
- `Views/Settings/NotificationSettingsView.swift`
- `Views/Shared/*`

## Current Startup Flow

1. App launches.
2. `AuthService` attempts Supabase session restore.
3. If unauthenticated, show `AuthView`.
4. If authenticated, show `HomeView`.
5. App root handles current user id:
   - Configure streak for user.
   - Clear in-memory sessions.
   - Load Supabase sessions.
   - Load Supabase profile.
   - Apply `profile.preferred_theme`.

## Current Auth Flow

1. User signs in with email/password.
2. Supabase Auth returns a session.
3. `AuthService.currentUser` is set.
4. App root loads user-scoped data.
5. On sign-out:
   - Supabase signs out.
   - Current user clears.
   - Sessions clear.
   - Profile clears.
   - Streak user scope clears.
   - Appearance resets to `.system`.

## Current Profile Flow

1. App root calls `ProfileStore.loadProfile(userId:)`.
2. `ProfileStore` selects the matching row from `profiles`.
3. Settings displays email, display name, and appearance.
4. Display name save updates `profiles.display_name`.
5. Appearance picker updates `profiles.preferred_theme`.

## Current Session Sync Flow

1. User completes a form.
2. `SessionSummaryView` shows answered questions.
3. Save creates a local session and inserts a Supabase row.
4. Past Sessions refreshes from Supabase on appear and pull-to-refresh.
5. RLS ensures User A only sees User A rows and User B only sees User B rows.

## Known Answer Storage Mismatch

iOS currently writes `answers_json` as a dictionary keyed by question id with object values containing:

- `question_id`
- `question_prompt`
- `answer_value`

The web app has a normalization layer and may produce or handle other shapes, including:

- Array of objects with prompt/answer
- Dictionary keyed by question id
- Existing iOS shape

iOS currently has tolerant decoding in `SessionSyncService` so web-created sessions can display. This should be standardized later.

Backlog reference:

- `UN-ARCH-001 Standardize session answer storage`

## Backlog References

- `UN-ARCH-001 Standardize session answer storage`
- `UN-ARCH-002 Shared form definition system`
- `UN-ARCH-003 Canonical form engine design`
- `UN-PROFILE-001 Move streak/completed_today to backend`

## Constraints For Future Work

- Do not edit `.pbxproj` directly while Xcode is open.
- Prefer Xcode tools for reads/writes/builds.
- Do not change Supabase schema unless explicitly requested.
- Do not change RLS unless explicitly requested.
- Keep the POC simple.
- Avoid adding forms/questions/answers tables until explicitly requested.
- Keep `answers_json` for the POC until `UN-ARCH-001`.
- Preserve notification functionality.
- Preserve User A/User B isolation.

## Current Recovery Task Guidance

When resuming work:

1. Inspect current files before editing.
2. Keep changes narrowly scoped.
3. Build with Xcode after edits.
4. If touching a view that uses environment objects, update previews.
5. If changing profile/session sync, verify sign-in/sign-out user isolation.
