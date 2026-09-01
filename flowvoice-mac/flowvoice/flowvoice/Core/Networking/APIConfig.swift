import Foundation

enum APIEnvironment {
    case local
    case production
}

enum APIConfig {

    // Change only this line
    static let environment: APIEnvironment = .local

    // MARK: - Production

    private static let productionBaseURL =
        "https://flowvoice-backend-1086205439072.asia-south1.run.app"

    // MARK: - Base URL

    static var baseURL: String {
        switch environment {

        case .local:
            return "http://127.0.0.1:8000"

        case .production:
            return productionBaseURL
        }
    }

    // MARK: - WebSocket

    static var webSocketURL: String {
        switch environment {

        case .local:
            return "ws://127.0.0.1:8000/ws/voice"

        case .production:
            let wsBaseURL =
                productionBaseURL
                    .replacingOccurrences(
                        of: "https://",
                        with: "wss://"
                    )
                    .replacingOccurrences(
                        of: "http://",
                        with: "ws://"
                    )

            return "\(wsBaseURL)/ws/voice"
        }
    }
}
