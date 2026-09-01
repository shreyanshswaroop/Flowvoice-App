import SwiftUI

struct SignInView: View {

    @EnvironmentObject var authManager: AuthManager

    @State private var email = ""
    @State private var password = ""

    let onCreateAccount: () -> Void
    

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 22
        ) {

            header

            socialButtons

            divider

            VStack(spacing: 14) {

                authField(
                    title: "Email",
                    text: $email,
                    placeholder: "you@example.com"
                )

                passwordField
            }

            if let error = authManager.errorMessage {

                Text(error)
                    .font(
                        .system(
                            size: 13,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(.red)
            }

            signInButton

            accountFooter
        }
    }

    // MARK: - Header

    private var header: some View {

        VStack(
            alignment: .leading,
            spacing: 7
        ) {

            Text("Welcome back")
                .font(
                    .system(
                        size: 32,
                        weight: .regular,
                        design: .serif
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.primaryText
                )

            Text("Sign in to continue to FlowVoice.")
                .font(
                    .system(
                        size: 15,
                        weight: .regular
                    )
                )
                .foregroundStyle(
                    .secondary
                )
        }
    }

    // MARK: - Social Buttons

    private var socialButtons: some View {

        HStack(spacing: 12) {

            socialIconButton {

                Image(
                    systemName: "apple.logo"
                )
                .font(
                    .system(
                        size: 17,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.primaryText
                )
            } action: {
                // Apple login comes next
            }

            socialIconButton {

                Image("GoogleLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: 18,
                        height: 18
                    )

            } action: {
                // Google login comes next
            }
        }
    }

    private func socialIconButton<Content: View>(
        @ViewBuilder content: () -> Content,
        action: @escaping () -> Void
    ) -> some View {

        Button(
            action: action
        ) {

            content()
                .frame(
                    maxWidth: .infinity
                )
                .frame(
                    height: 44
                )
        }
        .buttonStyle(.plain)
        .background {

            RoundedRectangle(
                cornerRadius: 11,
                style: .continuous
            )
            .fill(
                FlowVoiceTheme.inputSurface
            )
        }
        .overlay {

            RoundedRectangle(
                cornerRadius: 11,
                style: .continuous
            )
            .stroke(
                FlowVoiceTheme.hairline,
                lineWidth: 1
            )
        }
    }

    // MARK: - Divider

    private var divider: some View {

        HStack(spacing: 12) {

            Rectangle()
                .fill(
                    FlowVoiceTheme.divider
                )
                .frame(height: 1)

            Text("or")
                .font(
                    .system(
                        size: 12,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    .secondary
                )

            Rectangle()
                .fill(
                    FlowVoiceTheme.divider
                )
                .frame(height: 1)
        }
    }

    // MARK: - Password

    private var passwordField: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text("Password")
                .font(
                    .system(
                        size: 13,
                        weight: .medium
                    )
                )

            SecureField(
                "Enter your password",
                text: $password
            )
            .textFieldStyle(.plain)
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background {

                RoundedRectangle(
                    cornerRadius: 11,
                    style: .continuous
                )
                .fill(
                    FlowVoiceTheme.inputSurface
                )
            }
            .overlay {

                RoundedRectangle(
                    cornerRadius: 11,
                    style: .continuous
                )
                .stroke(
                    FlowVoiceTheme.hairline,
                    lineWidth: 1
                )
            }
        }
    }

    // MARK: - Sign In

    private var signInButton: some View {

        Button {

            Task {

                await authManager.login(
                    email: email,
                    password: password
                )
            }

        } label: {

            HStack {

                Spacer()

                if authManager.isLoading {

                    ProgressView()
                        .controlSize(.small)

                } else {

                    Text("Sign In")
                        .font(
                            .system(
                                size: 14,
                                weight: .semibold
                            )
                        )
                }

                Spacer()
            }
            .frame(height: 44)
            .foregroundStyle(
                FlowVoiceTheme.accentButtonText
            )
            .background(
                FlowVoiceTheme.accentButton,
                in:
                    RoundedRectangle(
                        cornerRadius: 11,
                        style: .continuous
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(
            email.isEmpty ||
            password.isEmpty ||
            authManager.isLoading
        )
    }

    // MARK: - Footer

    private var accountFooter: some View {

        HStack(spacing: 5) {

            Text(
                "Don't have an account?"
            )
            .foregroundStyle(
                .secondary
            )

            Button(
                "Create account"
            ) {

                onCreateAccount()
            }
            .buttonStyle(.plain)
            .fontWeight(.semibold)
        }
        .font(
            .system(
                size: 13
            )
        )
    }

    // MARK: - Field

    private func authField(
        title: String,
        text: Binding<String>,
        placeholder: String
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

            TextField(
                placeholder,
                text: text
            )
            .textFieldStyle(.plain)
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background {

                RoundedRectangle(
                    cornerRadius: 11,
                    style: .continuous
                )
                .fill(
                    FlowVoiceTheme.inputSurface
                )
            }
            .overlay {

                RoundedRectangle(
                    cornerRadius: 11,
                    style: .continuous
                )
                .stroke(
                    FlowVoiceTheme.hairline,
                    lineWidth: 1
                )
            }
        }
    }
}
