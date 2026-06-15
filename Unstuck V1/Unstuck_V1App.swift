//
//  Unstuck_V1App.swift
//  Unstuck V1
//
//  Created by Ben Mattern on 6/11/26.
//

import Supabase
import SwiftUI

@main
struct Unstuck_V1App: App {
    @StateObject private var authService = AuthService()
    @StateObject private var sessionStore = SessionStore()
    @StateObject private var streakStore = StreakStore()
    @StateObject private var appearanceStore = AppearanceStore()
    @StateObject private var profileStore = ProfileStore()
    @StateObject private var notificationScheduleStore = NotificationScheduleStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(AppTheme.screenBackground)
                } else if authService.isAuthenticated {
                    HomeView()
                } else {
                    AuthView()
                }
            }
            .environmentObject(authService)
            .environmentObject(sessionStore)
            .environmentObject(streakStore)
            .environmentObject(appearanceStore)
            .environmentObject(profileStore)
            .environmentObject(notificationScheduleStore)
            .preferredColorScheme(appearanceStore.appearance.colorScheme)
            .onChange(of: authService.currentUser?.id) { _, userId in
                handleAuthUserChange(userId)
            }
            .task {
                handleAuthUserChange(authService.currentUser?.id)
            }
        }
    }

    private func handleAuthUserChange(_ userId: UUID?) {
        streakStore.configureForUser(userId: userId)

        guard let userId else {
            sessionStore.clearInMemorySessions()
            profileStore.clear()
            notificationScheduleStore.clear()
            appearanceStore.resetToSystem()
            return
        }

        sessionStore.clearInMemorySessions()

        Task {
            await sessionStore.loadSessionsFromSupabase()
            await profileStore.loadProfile(userId: userId)
            await notificationScheduleStore.loadSchedules(userId: userId)

            if let preferredTheme = profileStore.profile?.preferredTheme {
                appearanceStore.applyProfileTheme(preferredTheme)
            } else {
                appearanceStore.resetToSystem()
            }
        }
    }
}
