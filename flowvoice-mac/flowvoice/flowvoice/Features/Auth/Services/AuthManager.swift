import Foundation
import Combine

@MainActor
final class AuthManager: ObservableObject {

    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var user: FlowVoiceUser?

    @Published var isExternalAuthInProgress = false

    private var baseURL: URL {
        URL(string: APIConfig.baseURL)!
    }

    init() {
        Task {
            await restoreSession()
        }
    }

    // MARK: - Restore Session

    func restoreSession() async {

        isLoading = true
        errorMessage = nil

        guard let token =
                KeychainService.shared.loadToken()
        else {
            isAuthenticated = false
            user = nil
            isLoading = false
            return
        }

        do {

            let currentUser =
                try await fetchCurrentUser(
                    token: token
                )

            user = currentUser
            isAuthenticated = true

        } catch {

            KeychainService.shared.deleteToken()

            user = nil
            isAuthenticated = false
        }

        isLoading = false
    }

    // MARK: - Sign Up

    func signUp(
        name: String,
        email: String,
        password: String
    ) async -> Bool {

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        guard let url = URL(
            string: "/auth/signup",
            relativeTo: baseURL
        ) else {
            errorMessage = "Invalid server URL."
            return false
        }

        let body = SignUpRequest(
            name: name,
            email: email,
            password: password
        )

        do {

            var request = URLRequest(
                url: url
            )

            request.httpMethod = "POST"

            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )

            request.httpBody =
                try JSONEncoder().encode(body)

            let (data, response) =
                try await URLSession.shared.data(
                    for: request
                )

            guard let httpResponse =
                    response as? HTTPURLResponse
            else {
                errorMessage =
                    "Invalid server response."
                return false
            }

            guard httpResponse.statusCode == 201
            else {
                errorMessage = parseError(
                    from: data
                )
                return false
            }

            let authResponse =
                try JSONDecoder().decode(
                    AuthResponse.self,
                    from: data
                )

            guard saveSession(
                authResponse
            ) else {
                return false
            }

            isAuthenticated = true

            return true

        } catch {

            errorMessage =
                error.localizedDescription

            return false
        }
    }

    // MARK: - Login

    func login(
        email: String,
        password: String
    ) async -> Bool {

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        guard let url = URL(
            string: "/auth/login",
            relativeTo: baseURL
        ) else {
            errorMessage = "Invalid server URL."
            return false
        }

        let body = LoginRequest(
            email: email,
            password: password
        )

        do {

            var request = URLRequest(
                url: url
            )

            request.httpMethod = "POST"

            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )

            request.httpBody =
                try JSONEncoder().encode(body)

            let (data, response) =
                try await URLSession.shared.data(
                    for: request
                )

            guard let httpResponse =
                    response as? HTTPURLResponse
            else {
                errorMessage =
                    "Invalid server response."
                return false
            }

            guard httpResponse.statusCode == 200
            else {
                errorMessage = parseError(
                    from: data
                )
                return false
            }

            let authResponse =
                try JSONDecoder().decode(
                    AuthResponse.self,
                    from: data
                )

            guard saveSession(
                authResponse
            ) else {
                return false
            }

            isAuthenticated = true

            return true

        } catch {

            errorMessage =
                error.localizedDescription

            return false
        }
    }

    // MARK: - Google Sign In

    func signInWithGoogle() async -> Bool {

        isLoading = true
        errorMessage = nil
        isExternalAuthInProgress = true

        AppWindowManager.shared
            .showExternalAuthWindow()

        defer {
            isLoading = false
        }

        do {

            let idToken =
                try await GoogleAuthService
                    .shared
                    .signIn()

            guard let url = URL(
                string: "/auth/google",
                relativeTo: baseURL
            ) else {

                errorMessage =
                    "Invalid server URL."

                await cancelExternalAuth()

                return false
            }

            let body = GoogleLoginRequest(
                idToken: idToken
            )

            var request = URLRequest(
                url: url
            )

            request.httpMethod = "POST"

            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )

            request.httpBody =
                try JSONEncoder().encode(body)

            let (data, response) =
                try await URLSession.shared.data(
                    for: request
                )

            guard let httpResponse =
                    response as? HTTPURLResponse
            else {

                errorMessage =
                    "Invalid server response."

                await cancelExternalAuth()

                return false
            }

            guard httpResponse.statusCode == 200
            else {

                errorMessage = parseError(
                    from: data
                )

                await cancelExternalAuth()

                return false
            }

            let authResponse =
                try JSONDecoder().decode(
                    AuthResponse.self,
                    from: data
                )

            guard saveSession(
                authResponse
            ) else {

                await cancelExternalAuth()

                return false
            }

            // Keep ExternalAuthView visible while
            // the window grows to dashboard size.
            await AppWindowManager.shared
                .expandToDashboardWindow()

            // Only swap to ContentView after
            // the expansion animation finishes.
            isExternalAuthInProgress = false
            isAuthenticated = true

            return true

        } catch {

            errorMessage =
                error.localizedDescription

            await cancelExternalAuth()

            return false
        }
    }

    // MARK: - Cancel External Auth

    private func cancelExternalAuth() async {

        isExternalAuthInProgress = false

        AppWindowManager.shared
            .showAuthWindow()
    }

    // MARK: - Logout

    func logout() {

        GoogleAuthService.shared
            .signOut()

        KeychainService.shared
            .deleteToken()

        user = nil
        isAuthenticated = false
        isExternalAuthInProgress = false
        errorMessage = nil

        AppWindowManager.shared
            .showAuthWindow()
    }

    // MARK: - Current User

    private func fetchCurrentUser(
        token: String
    ) async throws -> FlowVoiceUser {

        guard let url = URL(
            string: "/auth/me",
            relativeTo: baseURL
        ) else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(
            url: url
        )

        request.httpMethod = "GET"

        request.setValue(
            "Bearer \(token)",
            forHTTPHeaderField: "Authorization"
        )

        let (data, response) =
            try await URLSession.shared.data(
                for: request
            )

        guard let httpResponse =
                response as? HTTPURLResponse
        else {
            throw AuthError.invalidResponse
        }

        guard httpResponse.statusCode == 200
        else {
            throw AuthError.invalidSession
        }

        return try JSONDecoder().decode(
            FlowVoiceUser.self,
            from: data
        )
    }

    // MARK: - Save Session

    @discardableResult
    private func saveSession(
        _ response: AuthResponse
    ) -> Bool {

        let saved =
            KeychainService.shared
                .saveToken(
                    response.accessToken
                )

        guard saved else {

            user = nil
            isAuthenticated = false

            errorMessage =
                "Could not save your login securely."

            print(
                "FlowVoice: failed to save session to Keychain"
            )

            return false
        }

        user = response.user
        errorMessage = nil

        print(
            "FlowVoice session saved for:",
            response.user.email
        )

        return true
    }

    // MARK: - Parse API Error

    private func parseError(
        from data: Data
    ) -> String {

        if let apiError =
            try? JSONDecoder().decode(
                APIErrorResponse.self,
                from: data
            ) {

            return apiError.detail
        }

        if let rawResponse = String(
            data: data,
            encoding: .utf8
        ) {

            print(
                "FlowVoice API error:",
                rawResponse
            )
        }

        return "Unable to sign in. Check your email and password."
    }
}

// MARK: - Models

struct FlowVoiceUser:
    Codable,
    Identifiable {

    let id: String
    let name: String
    let email: String
    let provider: String
}

struct AuthResponse: Codable {

    let accessToken: String
    let tokenType: String
    let user: FlowVoiceUser

    enum CodingKeys:
        String,
        CodingKey {

        case accessToken = "access_token"
        case tokenType = "token_type"
        case user
    }
}

struct SignUpRequest: Codable {

    let name: String
    let email: String
    let password: String
}

struct LoginRequest: Codable {

    let email: String
    let password: String
}

struct GoogleLoginRequest: Codable {

    let idToken: String

    enum CodingKeys:
        String,
        CodingKey {

        case idToken = "id_token"
    }
}

struct APIErrorResponse: Codable {

    let detail: String
}

enum AuthError: Error {

    case invalidURL
    case invalidResponse
    case invalidSession
}
