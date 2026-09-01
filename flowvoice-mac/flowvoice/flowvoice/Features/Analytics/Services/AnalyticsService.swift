import Foundation

@MainActor
final class AnalyticsService {

    static let shared =
        AnalyticsService()

    private init() {}

    private var baseURL: URL {
        URL(string: APIConfig.baseURL)!
    }

    func fetchAnalytics()
        async throws
        -> AnalyticsResponse {

        guard let token =
            KeychainService
                .shared
                .loadToken()
        else {

            throw AnalyticsServiceError
                .noToken
        }

        guard let url =
            URL(
                string:
                    "/analytics",
                relativeTo:
                    baseURL
            )
        else {

            throw AnalyticsServiceError
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

            throw AnalyticsServiceError
                .invalidResponse
        }

        guard
            http.statusCode == 200
        else {

            if let body =
                String(
                    data: data,
                    encoding: .utf8
                ) {

                print(
                    "Analytics backend:",
                    body
                )
            }

            throw AnalyticsServiceError
                .requestFailed
        }

        return try JSONDecoder()
            .decode(
                AnalyticsResponse.self,
                from:
                    data
            )
    }
}


enum AnalyticsServiceError:
    Error {

    case noToken
    case invalidURL
    case invalidResponse
    case requestFailed
}
