import SwiftUI

struct SignInView: View {

    @EnvironmentObject var authManager: AuthManager

    @State private var email = ""
    @State private var password = ""

    let onCreateAccount: () -> Void

    var body: some View {

        VStack(spacing: 18) {

            header

            googleButton

            divider

            VStack(spacing: 14) {

                authField(
                    title: "Email",
                    placeholder: "you@example.com",
                    text: $email
                )

                passwordField(
                    title: "Password",
                    placeholder: "",
                    text: $password
                )
            }

            if let error = authManager.errorMessage {

                Text(error)
                    .font(
                        .system(
                            size: 12,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(.red)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
            }

            signInButton

            footer
        }
        .foregroundStyle(
            FlowVoiceTheme.primaryText
        )
        .onAppear {
            authManager.errorMessage = nil
        }
    }

    // MARK: - Header

    private var header: some View {

        VStack(spacing: 8) {

            Text("Sign in")
                .font(
                    .system(
                        size: 22,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.primaryText
                )
        }
    }

    // MARK: - Google

    private var googleButton: some View {

        Button {

            authManager.errorMessage = nil

            Task {
                await authManager
                    .signInWithGoogle()
            }

        } label: {

            HStack(spacing: 10) {

                Image("GoogleLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: 18,
                        height: 18
                    )

                Text("Sign in with Google")
                    .font(
                        .system(
                            size: 14,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        FlowVoiceTheme.primaryText
                    )

                Spacer()
            }
            .frame(
                maxWidth: .infinity
            )
            .padding(
                .horizontal,
                16
            )
            .frame(height: 46)
            .background(
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .fill(
                    FlowVoiceTheme.surface
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .stroke(
                    FlowVoiceTheme.hairline,
                    lineWidth: 1
                )
            }
        }
        .buttonStyle(.plain)
        .disabled(
            authManager.isLoading
        )
    }

    // MARK: - Divider

    private var divider: some View {

        Rectangle()
            .fill(
                FlowVoiceTheme.divider
            )
            .frame(height: 1)
            .padding(
                .vertical,
                8
            )
    }

    // MARK: - Sign In Button

    private var signInButton: some View {

        Button {

            authManager.errorMessage = nil

            let cleanEmail =
                email.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

            guard isValidEmail(cleanEmail)
            else {

                authManager.errorMessage =
                    "Please enter a valid email address."

                return
            }

            guard password.count >= 8
            else {

                authManager.errorMessage =
                    "Password must be at least 8 characters."

                return
            }

            Task {

                await authManager.login(
                    email: cleanEmail,
                    password: password
                )
            }

        } label: {

            HStack {

                Spacer()

                if authManager.isLoading {

                    ProgressView()
                        .controlSize(.small)
                        .tint(
                            FlowVoiceTheme.accentButtonText
                        )

                } else {

                    Text("Sign in")
                        .font(
                            .system(
                                size: 14,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(
                            FlowVoiceTheme.accentButtonText
                        )
                }

                Spacer()
            }
            .frame(height: 48)
            .background(
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .fill(buttonFill)
            )
        }
        .buttonStyle(.plain)
        .disabled(
            email.isEmpty ||
            password.isEmpty ||
            authManager.isLoading
        )
    }

    private var buttonFill: Color {

        if email.isEmpty ||
            password.isEmpty {

            return FlowVoiceTheme.primaryText.opacity(0.18)

        } else {

            return FlowVoiceTheme.accentButton
        }
    }

    // MARK: - Footer

    private var footer: some View {

        HStack(spacing: 4) {

            Text(
                "Don't have an account?"
            )
            .foregroundStyle(
                FlowVoiceTheme.secondaryText
            )

            Button("Sign up") {

                authManager.errorMessage = nil

                onCreateAccount()
            }
            .buttonStyle(.plain)
            .foregroundStyle(
                FlowVoiceTheme.primaryText
            )
            .underline()
        }
        .font(
            .system(size: 13)
        )
        .padding(
            .top,
            2
        )
    }

    // MARK: - Email Field

    private func authField(
        title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text(title)
                .font(
                    .system(
                        size: 13,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.primaryText
                )

            TextField(
                placeholder,
                text: text
            )
            .textFieldStyle(.plain)
            .padding(
                .horizontal,
                14
            )
            .frame(height: 46)
            .background(
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .fill(
                    FlowVoiceTheme.inputSurface
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .stroke(
                    FlowVoiceTheme.hairline,
                    lineWidth: 1
                )
            }
            .foregroundStyle(
                FlowVoiceTheme.primaryText
            )
        }
    }

    // MARK: - Password Field

    private func passwordField(
        title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text(title)
                .font(
                    .system(
                        size: 13,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.primaryText
                )

            SecureField(
                placeholder,
                text: text
            )
            .textFieldStyle(.plain)
            .padding(
                .horizontal,
                14
            )
            .frame(height: 46)
            .background(
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .fill(
                    FlowVoiceTheme.inputSurface
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .stroke(
                    FlowVoiceTheme.hairline,
                    lineWidth: 1
                )
            }
            .foregroundStyle(
                FlowVoiceTheme.primaryText
            )
        }
    }

    // MARK: - Email Validation

    private func isValidEmail(
        _ email: String
    ) -> Bool {

        let pattern =
            #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#

        return email.range(
            of: pattern,
            options: .regularExpression
        ) != nil
    }
}
