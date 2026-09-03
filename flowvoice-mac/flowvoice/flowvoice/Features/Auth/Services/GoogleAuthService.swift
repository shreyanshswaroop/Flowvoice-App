import Foundation
import AppKit
import GoogleSignIn

@MainActor
final class GoogleAuthService {

    static let shared = GoogleAuthService()

    private init() {}

    func signIn() async throws -> String {

        guard let clientID = Bundle.main.object(
            forInfoDictionaryKey: "GIDClientID"
        ) as? String else {
            throw GoogleAuthError.missingClientID
        }

       

        GIDSignIn.sharedInstance.configuration =
            GIDConfiguration( 
                clientID: clientID
            )

        guard let window =
            NSApplication.shared.keyWindow
                ?? NSApplication.shared.windows.first(
                    where: {
                        $0.isVisible &&
                        !($0 is NSPanel)
                    }
                )
        else {
            throw GoogleAuthError.noWindow
        }

        let result = try await GIDSignIn
            .sharedInstance
            .signIn(
                withPresenting: window
            )

        guard let token =
            result.user.idToken?.tokenString
        else {
            throw GoogleAuthError.missingToken
        }

        return token
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }
}

enum GoogleAuthError: LocalizedError {

    case missingClientID
   
    case noWindow
    case missingToken

    var errorDescription: String? {

        switch self {

        case .missingClientID:
            return "Google client ID is missing."


        case .noWindow:
            return "Unable to find the FlowVoice window."

        case .missingToken:
            return "Google did not return an ID token."
        }
    }
}
