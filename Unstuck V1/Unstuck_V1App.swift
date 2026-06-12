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

        guard userId != nil else {
            sessionStore.clearInMemorySessions()
            return
        }

        Task {
            await sessionStore.loadSessionsFromSupabase()
        }
    }
}
