// RootView.swift

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        Group {
            if authManager.isLoading {
                VStack(spacing: 14) {
                    ProgressView()
                        .controlSize(.large)

                    Text("Loading FlowVoice…")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )

            } else if authManager.isAuthenticated {
                ContentView()

            } else {
                AuthView()
            }
        }
        .preferredColorScheme(.dark)
        .environment(
            \.colorScheme,
            .dark
        )
        .background(
            FlowVoiceTheme.pageBackground
        )
    }
}
