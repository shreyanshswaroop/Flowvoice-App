import Foundation

@MainActor
final class InsightsService {

    static let shared =
        InsightsService()

    private init() {}

    private var baseURL: URL {
        URL(string: APIConfig.baseURL)!
    }

    // MARK: - Fetch

    func fetchInsights()
        async throws
        -> InsightsResponse {

        guard let token =
            KeychainService
                .shared
                .loadToken()
        else {

            throw InsightsServiceError
                .noToken
        }

        guard let url =
            URL(
                string:
                    "/insights",
                relativeTo:
                    baseURL
            )
        else {

            throw InsightsServiceError
                .invalidURL
        }

        var request =
            URLRequest(
                url: url
            )

        request.httpMethod =
            "GET"

        request.setValue(
            "Bearer \(token)",
            forHTTPHeaderField:
                "Authorization"
        )

        let (data, response) =
            try await URLSession
                .shared
                .data(
                    for:
                        request
                )

        guard let http =
            response
                as? HTTPURLResponse
        else {

            throw InsightsServiceError
                .invalidResponse
        }

        guard
            http.statusCode == 200
        else {

            print(
                "Fetch insights failed:",
                http.statusCode
            )

            throw InsightsServiceError
                .requestFailed
        }

        return try JSONDecoder()
            .decode(
                InsightsResponse.self,
                from:
                    data
            )
    }

    // MARK: - Generate

    func generateInsights()
        async throws
        -> InsightsResponse {

        guard let token =
            KeychainService
                .shared
                .loadToken()
        else {

            throw InsightsServiceError
                .noToken
        }

        guard let url =
            URL(
                string:
                    "/insights/generate",
                relativeTo:
                    baseURL
            )
        else {

            throw InsightsServiceError
                .invalidURL
        }

        var request =
            URLRequest(
                url: url
            )

        request.httpMethod =
            "POST"

        request.setValue(
            "Bearer \(token)",
            forHTTPHeaderField:
                "Authorization"
        )

        let (data, response) =
            try await URLSession
                .shared
                .data(
                    for:
                        request
                )

        guard let http =
            response
                as? HTTPURLResponse
        else {

            throw InsightsServiceError
                .invalidResponse
        }

        guard
            http.statusCode == 200
        else {

            if let body =
                String(
                    data: data,
                    encoding:
                        .utf8
                ) {

                print(
                    "Insights backend:",
                    body
                )
            }

            throw InsightsServiceError
                .requestFailed
        }

        return try JSONDecoder()
            .decode(
                InsightsResponse.self,
                from:
                    data
            )
    }
}


enum InsightsServiceError:
    Error {

    case noToken
    case invalidURL
    case invalidResponse
    case requestFailed
}
