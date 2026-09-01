import SwiftUI

struct AccountSettingsView: View {

    @EnvironmentObject var authManager: AuthManager

    var body: some View {

        settingsPage(
            title: "Account"
        ) {

            SettingsInfoRow(
                title: "Name",
                value: authManager.user?.name ?? "—"
            )

            SettingsInfoRow(
                title: "Email",
                value: authManager.user?.email ?? "—"
            )

            SettingsInfoRow(
                title: "Signed in with",
                value: providerName
            )

            SettingsInfoRow(
                title: "Plan",
                value: "Free"
            )

            SettingsActionRow(
                title: "Manage account"
            )

            Button {

                authManager.logout()

            } label: {

                HStack {

                    Text("Sign Out")
                        .font(
                            .system(
                                size: 14,
                                weight: .medium
                            )
                        )

                    Spacer()

                    Image(
                        systemName:
                            "rectangle.portrait.and.arrow.right"
                    )
                }
                .foregroundStyle(.red)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
        }
    }

    private var providerName: String {

        guard let provider = authManager.user?.provider else {
            return "—"
        }

        switch provider.lowercased() {

        case "google":
            return "Google"

        case "apple":
            return "Apple"

        case "email", "local":
            return "Email"

        default:
            return provider.capitalized
        }
    }
}
