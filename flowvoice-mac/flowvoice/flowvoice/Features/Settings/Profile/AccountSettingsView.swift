import SwiftUI

struct ProfileSettingsView: View {

    @EnvironmentObject var authManager: AuthManager

    @State private var fullName = ""
    @State private var jobTitle = ""
    @State private var linkedInUsername = ""
    @State private var companyName = ""
    @State private var companyDescription = ""

    var body: some View {

        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 28
            ) {
                header
                accountSection
                companySection
                accountManagementSection
            }
            .frame(
                maxWidth: 620,
                alignment: .leading
            )
            .padding(.horizontal, 28)
            .padding(.top, 26)
            .padding(.bottom, 50)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .top
        )
        .onAppear {
            fullName =
                authManager.user?.name ?? ""
        }
    }

    // MARK: - Header

    private var header: some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            Text("Profile")
                .font(
                    .system(
                        size: 30,
                        weight: .regular,
                        design: .serif
                    )
                )

            Text(
                "FlowVoice works best knowing a little about you."
            )
            .font(
                .system(size: 13)
            )
            .foregroundStyle(
                Color.secondary
            )
        }
    }

    // MARK: - Account

    private var accountSection: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            sectionTitle("Account")

            SettingsCard {

                ProfileValueRow(
                    title: "Email"
                ) {

                    HStack(
                        spacing: 10
                    ) {

                        Text(
                            authManager.user?.email ?? "—"
                        )
                        .foregroundStyle(
                            Color.secondary
                        )

                        profileAvatar
                    }
                }

                divider

                ProfileFieldRow(
                    title: "Full name",
                    text: $fullName,
                    placeholder: "Your name"
                )

                divider

                ProfileFieldRow(
                    title: "Job title",
                    text: $jobTitle,
                    placeholder: "Software Engineer"
                )

                divider

                ProfileLinkedInRow(
                    text: $linkedInUsername
                )
            }
        }
    }

    // MARK: - Company

    private var companySection: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            sectionTitle("Your company")

            SettingsCard {

                ProfileFieldRow(
                    title: "Company name",
                    text: $companyName,
                    placeholder: "Acme Inc."
                )

                divider

                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {

                    Text("Company description")
                        .font(
                            .system(
                                size: 13,
                                weight: .medium
                            )
                        )

                    Text(
                        "FlowVoice can use this context when generating meeting notes."
                    )
                    .font(
                        .system(size: 12)
                    )
                    .foregroundStyle(
                        Color.secondary
                    )

                    TextEditor(
                        text: $companyDescription
                    )
                    .font(
                        .system(size: 13)
                    )
                    .scrollContentBackground(
                        .hidden
                    )
                    .padding(8)
                    .frame(
                        minHeight: 90
                    )
                    .background {
                        RoundedRectangle(
                            cornerRadius: 8,
                            style: .continuous
                        )
                        .fill(
                            Color.primary
                                .opacity(0.035)
                        )
                    }
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: 8,
                            style: .continuous
                        )
                        .stroke(
                            Color.primary
                                .opacity(0.10),
                            lineWidth: 1
                        )
                    }
                }
                .padding(.vertical, 14)
            }
        }
    }

    // MARK: - Account Management

    private var accountManagementSection: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            sectionTitle(
                "Account management"
            )

            SettingsCard {

                ProfileActionRow(
                    title:
                        "Import notes from another account",
                    subtitle:
                        "Migrate notes from another account into this one.",
                    buttonTitle:
                        "Import"
                ) {
                    print("Import")
                }

                divider

                ProfileActionRow(
                    title:
                        "Export historical data",
                    subtitle:
                        "Generate a CSV export of your FlowVoice data.",
                    buttonTitle:
                        "Generate CSV"
                ) {
                    print("Generate CSV")
                }

                divider

               
            }
        }
    }

    // MARK: - Shared

    private func sectionTitle(
        _ title: String
    ) -> some View {

        Text(title)
            .font(
                .system(
                    size: 12,
                    weight: .medium
                )
            )
            .foregroundStyle(
                Color.secondary
            )
            .padding(.leading, 8)
    }

    private var divider: some View {

        Rectangle()
            .fill(
                Color.primary
                    .opacity(0.08)
            )
            .frame(height: 1)
    }

    private var profileAvatar: some View {

        ZStack {

            Circle()
                .fill(
                    Color.orange
                        .opacity(0.18)
                )

            Circle()
                .stroke(
                    Color.orange
                        .opacity(0.35),
                    lineWidth: 1
                )

            Text(userInitial)
                .font(
                    .system(
                        size: 14,
                        weight: .medium,
                        design: .serif
                    )
                )
                .foregroundStyle(
                    Color.orange
                )
        }
        .frame(
            width: 34,
            height: 34
        )
    }

    private var userInitial: String {

        String(
            (authManager.user?.name ?? "F")
                .prefix(1)
        )
        .uppercased()
    }
}

// MARK: - Settings Card

private struct SettingsCard<Content: View>: View {

    @ViewBuilder
    let content: Content

    var body: some View {

        VStack(
            spacing: 0
        ) {
            content
        }
        .padding(.horizontal, 16)
        .background {
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
            .fill(
                Color.primary
                    .opacity(0.025)
            )
        }
        .overlay {
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
            .stroke(
                Color.primary
                    .opacity(0.10),
                lineWidth: 1
            )
        }
    }
}

// MARK: - Value Row

private struct ProfileValueRow<Content: View>: View {

    let title: String

    @ViewBuilder
    let content: Content

    var body: some View {

        HStack {

            Text(title)
                .font(
                    .system(
                        size: 13,
                        weight: .medium
                    )
                )

            Spacer()

            content
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Field Row

private struct ProfileFieldRow: View {

    let title: String

    @Binding var text: String

    let placeholder: String

    var body: some View {

        HStack(
            spacing: 20
        ) {

            Text(title)
                .font(
                    .system(
                        size: 13,
                        weight: .medium
                    )
                )

            Spacer()

            TextField(
                placeholder,
                text: $text
            )
            .textFieldStyle(.plain)
            .font(
                .system(size: 13)
            )
            .padding(
                .horizontal,
                10
            )
            .frame(
                width: 225,
                height: 32
            )
            .background {
                RoundedRectangle(
                    cornerRadius: 7,
                    style: .continuous
                )
                .fill(
                    Color.primary
                        .opacity(0.035)
                )
            }
            .overlay {
                RoundedRectangle(
                    cornerRadius: 7,
                    style: .continuous
                )
                .stroke(
                    Color.primary
                        .opacity(0.10),
                    lineWidth: 1
                )
            }
        }
        .padding(.vertical, 11)
    }
}

// MARK: - LinkedIn

private struct ProfileLinkedInRow: View {

    @Binding var text: String

    var body: some View {

        HStack(
            spacing: 20
        ) {

            Text("LinkedIn username")
                .font(
                    .system(
                        size: 13,
                        weight: .medium
                    )
                )

            Spacer()

            HStack(
                spacing: 0
            ) {

                Text("linkedin.com/in/")
                    .font(
                        .system(size: 12)
                    )
                    .foregroundStyle(
                        Color.secondary
                    )
                    .padding(
                        .horizontal,
                        10
                    )

                Rectangle()
                    .fill(
                        Color.primary
                            .opacity(0.10)
                    )
                    .frame(
                        width: 1
                    )

                TextField(
                    "username",
                    text: $text
                )
                .textFieldStyle(.plain)
                .font(
                    .system(size: 13)
                )
                .padding(
                    .horizontal,
                    10
                )
            }
            .frame(
                width: 350,
                height: 32
            )
            .background {
                RoundedRectangle(
                    cornerRadius: 7,
                    style: .continuous
                )
                .fill(
                    Color.primary
                        .opacity(0.035)
                )
            }
            .overlay {
                RoundedRectangle(
                    cornerRadius: 7,
                    style: .continuous
                )
                .stroke(
                    Color.primary
                        .opacity(0.10),
                    lineWidth: 1
                )
            }
        }
        .padding(.vertical, 11)
    }
}

// MARK: - Action Row

private struct ProfileActionRow: View {

    let title: String
    let subtitle: String
    let buttonTitle: String

    var isDestructive: Bool = false

    let action: () -> Void

    var body: some View {

        HStack(
            spacing: 20
        ) {

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text(title)
                    .font(
                        .system(
                            size: 13,
                            weight: .medium
                        )
                    )

                Text(subtitle)
                    .font(
                        .system(size: 12)
                    )
                    .foregroundStyle(
                        Color.secondary
                    )
            }

            Spacer()

            Button(
                buttonTitle,
                action: action
            )
            .buttonStyle(.plain)
            .font(
                .system(
                    size: 12,
                    weight: .medium
                )
            )
            .foregroundStyle(
                isDestructive
                    ? Color.red
                    : Color.primary
            )
            .padding(
                .horizontal,
                14
            )
            .frame(
                height: 30
            )
            .background {
                Capsule()
                    .fill(
                        Color.primary
                            .opacity(0.045)
                    )
            }
            .overlay {
                Capsule()
                    .stroke(
                        Color.primary
                            .opacity(0.10),
                        lineWidth: 1
                    )
            }
        }
        .padding(.vertical, 13)
    }
}
