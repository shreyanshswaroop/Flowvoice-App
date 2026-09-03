import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    let onSignIn: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            header

            googleButton

            divider

            VStack(spacing: 14) {
                authField(
                    title: "Name",
                    placeholder: "Your name",
                    text: $name
                )

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

                passwordField(
                    title: "Confirm Password",
                    placeholder: "",
                    text: $confirmPassword
                )
            }

            if let error = authManager.errorMessage {
                Text(error)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            signUpButton

            footer
        }
        .foregroundStyle(
            FlowVoiceTheme.primaryText
        )
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Create an account")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(
                    FlowVoiceTheme.primaryText
                )
        }
    }

    private var googleButton: some View {
        Button {
            Task {
                await authManager.signInWithGoogle()
            }
        } label: {
            HStack(spacing: 10) {
                Image("GoogleLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)

                Text("Sign up with Google")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(
                        FlowVoiceTheme.primaryText
                    )

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(FlowVoiceTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(FlowVoiceTheme.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var divider: some View {
        Rectangle()
            .fill(FlowVoiceTheme.divider)
            .frame(height: 1)
            .padding(.vertical, 8)
    }

    private var signUpButton: some View {
        Button {
            guard password == confirmPassword else {
                authManager.errorMessage = "Passwords do not match."
                return
            }

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
                        .tint(
                            FlowVoiceTheme.accentButtonText
                        )
                } else {
                    Text("Sign up")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(
                            FlowVoiceTheme.accentButtonText
                        )
                }

                Spacer()
            }
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(buttonFill)
            )
        }
        .buttonStyle(.plain)
        .disabled(
            name.isEmpty ||
            email.isEmpty ||
            password.isEmpty ||
            confirmPassword.isEmpty ||
            authManager.isLoading
        )
    }

    private var buttonFill: Color {
        if name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty {
            return FlowVoiceTheme.primaryText.opacity(0.18)
        } else {
            return FlowVoiceTheme.accentButton
        }
    }

    private var footer: some View {
        HStack(spacing: 4) {
            Text("Already registered?")
                .foregroundStyle(FlowVoiceTheme.secondaryText)

            Button("Sign in") {
                onSignIn()
            }
            .buttonStyle(.plain)
            .foregroundStyle(
                FlowVoiceTheme.primaryText
            )
            .underline()
        }
        .font(.system(size: 13))
        .padding(.top, 2)
    }

    private func authField(
        title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(FlowVoiceTheme.primaryText)

            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(FlowVoiceTheme.inputSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(FlowVoiceTheme.hairline, lineWidth: 1)
                )
                .foregroundStyle(
                    FlowVoiceTheme.primaryText
                )
        }
    }

    private func passwordField(
        title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(FlowVoiceTheme.primaryText)

            SecureField(placeholder, text: text)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(FlowVoiceTheme.inputSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(FlowVoiceTheme.hairline, lineWidth: 1)
                )
                .foregroundStyle(
                    FlowVoiceTheme.primaryText
                )
        }
    }
}
