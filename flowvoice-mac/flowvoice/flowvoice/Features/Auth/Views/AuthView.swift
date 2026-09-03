import SwiftUI

struct AuthView: View {

    @EnvironmentObject var authManager: AuthManager

    @State private var authMode: AuthMode = .signIn

    private enum AuthMode {
        case signIn
        case signUp
    }

    var body: some View {
        ZStack {

            FlowVoiceTheme.pageBackground
                .ignoresSafeArea()

            VStack {

                Spacer(minLength: 40)

                brandHeader

                Spacer()

                Group {

                    switch authMode {

                    case .signIn:

                        SignInView {
                            withAnimation(
                                .easeInOut(duration: 0.18)
                            ) {
                                authManager.errorMessage = nil
                                authMode = .signUp
                            }
                        }

                    case .signUp:

                        SignUpView {
                            withAnimation(
                                .easeInOut(duration: 0.18)
                            ) {
                                authManager.errorMessage = nil
                                authMode = .signIn
                            }
                        }
                    }
                }
                .environmentObject(authManager)
                .frame(width: 380)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
    }

    private var brandHeader: some View {
        Text("FlowVoice")
            .font(
                .system(
                    size: 35,
                    weight: .medium,
                    design: .serif
                )
            )
            .tracking(-0.5)
            .foregroundStyle(
                FlowVoiceTheme.primaryText
            )
            .padding(.top, 12)
    }
}
