import SwiftUI

struct SignUpView: View {

    @EnvironmentObject var authManager: AuthManager

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    let onSignIn: () -> Void

    private var passwordsMatch: Bool {
        password == confirmPassword
    }

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 20
        ) {

            header

            socialButtons

            divider

            VStack(spacing: 14) {

                authField(
                    title: "Name",
                    text: $name,
                    placeholder: "Your name"
                )

                authField(
                    title: "Email",
                    text: $email,
                    placeholder: "you@example.com"
                )

                secureField(
                    title: "Password",
                    text: $password,
                    placeholder: "At least 8 characters"
                )

                secureField(
                    title: "Confirm password",
                    text: $confirmPassword,
                    placeholder: "Enter password again"
                )
            }

            if !confirmPassword.isEmpty &&
                !passwordsMatch {

                Text(
                    "Passwords do not match."
                )
                .font(
                    .system(
                        size: 13,
                        weight: .medium
                    )
                )
                .foregroundStyle(.red)
            }

            if let error =
                authManager.errorMessage {

                Text(error)
                    .font(
                        .system(
                            size: 13,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(.red)
            }

            createAccountButton

            accountFooter
        }
    }

    // MARK: - Header

    private var header: some View {

        VStack(
            alignment: .leading,
            spacing: 7
        ) {

            Text(
                "Create your account"
            )
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

            Text(
                "Start using FlowVoice across your Mac."
            )
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
                // Apple signup comes next
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
                // Google signup comes next
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

    // MARK: - Create Account

    private var createAccountButton: some View {

        Button {

            Task {

                await authManager.signUp(
                    name: name,
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

                    Text(
                        "Create Account"
                    )
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
            name.isEmpty ||
            email.isEmpty ||
            password.count < 8 ||
            !passwordsMatch ||
            authManager.isLoading
        )
    }

    // MARK: - Footer

    private var accountFooter: some View {

        HStack(spacing: 5) {

            Text(
                "Already have an account?"
            )
            .foregroundStyle(
                .secondary
            )

            Button(
                "Sign in"
            ) {

                onSignIn()
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

    // MARK: - Text Field

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

    // MARK: - Secure Field

    private func secureField(
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

            SecureField(
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
