import SwiftUI

struct RootView: View {

    @EnvironmentObject var authManager: AuthManager

    var body: some View {

        Group {

            if authManager.isExternalAuthInProgress {

                ExternalAuthView()

            } else if authManager.isLoading {

                VStack(spacing: 14) {

                    ProgressView()
                        .controlSize(.large)

                    Text("Loading FlowVoice…")
                        .font(
                            .system(
                                size: 14,
                                weight: .medium
                            )
                        )
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
                    .onAppear {
                        AppWindowManager.shared
                            .showAuthWindow()
                    }
            }
        }
        .onChange(
            of: authManager.isAuthenticated
        ) { _, isAuthenticated in

            if !isAuthenticated &&
                !authManager.isExternalAuthInProgress {

                AppWindowManager.shared
                    .showAuthWindow()
            }
        }
        .background(
            FlowVoiceTheme.pageBackground
        )
    }
}
