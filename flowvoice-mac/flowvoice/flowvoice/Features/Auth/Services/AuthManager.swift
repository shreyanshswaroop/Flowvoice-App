import Foundation
import Combine
import AppKit

@MainActor
final class AuthManager: ObservableObject {

    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var errorMessage: String?

    @Published var user: FlowVoiceUser?

    private var baseURL: URL {
        URL(string: APIConfig.baseURL)!
    }

    private let websiteSignInURL =
        URL(string: "http://localhost:3000/sign-in")!

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
            var request = URLRequest(url: url)

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
                errorMessage = "Invalid server response."
                return false
            }

            if httpResponse.statusCode ==
                201 {

                let authResponse =
                    try JSONDecoder().decode(
                        AuthResponse.self,
                        from: data
                    )

                saveSession(
                    authResponse
                )

                return true
            }

            errorMessage =
                parseError(
                    from: data
                )

            return false

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
            var request =
                URLRequest(url: url)

            request.httpMethod =
                "POST"

            request.setValue(
                "application/json",
                forHTTPHeaderField:
                    "Content-Type"
            )

            request.httpBody =
                try JSONEncoder().encode(
                    body
                )

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

            if httpResponse.statusCode ==
                200 {

                let authResponse =
                    try JSONDecoder().decode(
                        AuthResponse.self,
                        from: data
                    )

                saveSession(
                    authResponse
                )

                return true
            }

            errorMessage =
                parseError(
                    from: data
                )

            return false

        } catch {
            errorMessage =
                error.localizedDescription

            return false
        }
    }

    // MARK: - Logout

    func logout() {
        KeychainService.shared.deleteToken()

        user = nil
        isAuthenticated = false
        errorMessage = nil
    }

    // MARK: - Website Auth

    func openWebsiteAuth() {
        guard var components =
                URLComponents(
                    url: websiteSignInURL,
                    resolvingAgainstBaseURL: false
                )
        else {
            errorMessage =
                "Invalid website URL."

            return
        }

        components.queryItems = [
            URLQueryItem(
                name: "redirectTo",
                value: "mumbl://auth/callback"
            )
        ]

        guard let url =
                components.url
        else {
            errorMessage =
                "Invalid website URL."

            return
        }

        NSWorkspace.shared.open(url)
    }

    func handleAuthCallback(
        _ url: URL
    ) {
        guard
            url.scheme == "mumbl",
            url.host == "auth",
            url.path == "/callback",
            let components =
                URLComponents(
                    url: url,
                    resolvingAgainstBaseURL: false
                )
        else {
            return
        }

        let queryItems =
            components.queryItems ?? []

        func value(
            _ name: String
        ) -> String? {
            queryItems.first {
                $0.name == name
            }?.value
        }

        guard
            let token =
                value("access_token"),
            !token.isEmpty,
            let id =
                value("user_id"),
            let email =
                value("email")
        else {
            errorMessage =
                "Could not complete sign in."

            return
        }

        let user =
            FlowVoiceUser(
                id: id,
                name: value("name") ?? "",
                email: email,
                provider: value("provider") ?? "email"
            )

        saveSession(
            AuthResponse(
                accessToken: token,
                tokenType: value("token_type") ?? "bearer",
                user: user
            )
        )

        isLoading = false
        errorMessage = nil
        NSApplication.shared.activate(
            ignoringOtherApps: true
        )

        closeDuplicateAppWindows()
    }

    private func closeDuplicateAppWindows() {
        let normalWindows =
            NSApplication.shared.windows.filter { window in
                window.level == .normal &&
                window.isVisible
            }

        guard let mainWindow =
                normalWindows.first
        else {
            return
        }

        normalWindows.dropFirst().forEach { window in
            window.close()
        }

        mainWindow.makeKeyAndOrderFront(nil)
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

        var request =
            URLRequest(url: url)

        request.httpMethod =
            "GET"

        request.setValue(
            "Bearer \(token)",
            forHTTPHeaderField:
                "Authorization"
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

        guard httpResponse.statusCode ==
                200
        else {
            throw AuthError.invalidSession
        }

        return try JSONDecoder().decode(
            FlowVoiceUser.self,
            from: data
        )
    }

    // MARK: - Save Session

    private func saveSession(
        _ response: AuthResponse
    ) {
        KeychainService.shared.saveToken(
            response.accessToken
        )

        user = response.user
        isAuthenticated = true
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

        return "Something went wrong."
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

struct AuthResponse:
    Codable {

    let accessToken: String
    let tokenType: String
    let user: FlowVoiceUser

    enum CodingKeys:
        String,
        CodingKey {

        case accessToken =
            "access_token"

        case tokenType =
            "token_type"

        case user
    }
}

struct SignUpRequest:
    Codable {

    let name: String
    let email: String
    let password: String
}

struct LoginRequest:
    Codable {

    let email: String
    let password: String
}

struct APIErrorResponse:
    Codable {

    let detail: String
}

enum AuthError: Error {
    case invalidURL
    case invalidResponse
    case invalidSession
}
