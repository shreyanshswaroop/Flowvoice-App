import Foundation

struct RemoteDictation: Codable, Identifiable {

    let id: String
    let text: String
    let wordCount: Int
    let durationSeconds: Int?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case wordCount = "word_count"
        case durationSeconds = "duration_seconds"
        case createdAt = "created_at"
    }
}

private struct CreateDictationBody: Codable {
    let text: String
    let durationSeconds: Int?

    enum CodingKeys: String, CodingKey {
        case text
        case durationSeconds = "duration_seconds"
    }
}

@MainActor
final class DictationService {

    static let shared =
        DictationService()

    private init() {}

    private var baseURL: URL {
        URL(string: APIConfig.baseURL)!
    }

    // MARK: - Fetch

    func fetchDictations() async throws
        -> [RemoteDictation] {

        guard let token =
            KeychainService.shared.loadToken()
        else {
            throw DictationServiceError.noToken
        }

        guard let url =
            URL(
                string: "/dictations",
                relativeTo: baseURL
            )
        else {
            throw DictationServiceError.invalidURL
        }

        var request =
            URLRequest(url: url)

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
            throw DictationServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200
        else {
            throw DictationServiceError.requestFailed
        }

        return try JSONDecoder().decode(
            [RemoteDictation].self,
            from: data
        )
    }

    // MARK: - Save

    func saveDictation(
        text: String,
        durationSeconds: Int?
    ) async throws -> RemoteDictation {

        guard let token =
            KeychainService.shared.loadToken()
        else {
            throw DictationServiceError.noToken
        }

        guard let url =
            URL(
                string: "/dictations",
                relativeTo: baseURL
            )
        else {
            throw DictationServiceError.invalidURL
        }

        var request =
            URLRequest(url: url)

        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        request.setValue(
            "Bearer \(token)",
            forHTTPHeaderField: "Authorization"
        )

        request.httpBody =
            try JSONEncoder().encode(
                CreateDictationBody(
                    text: text,
                    durationSeconds: durationSeconds
                )
            )

        let (data, response) =
            try await URLSession.shared.data(
                for: request
            )

        guard let httpResponse =
            response as? HTTPURLResponse
        else {
            throw DictationServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 201
        else {
            throw DictationServiceError.requestFailed
        }

        return try JSONDecoder().decode(
            RemoteDictation.self,
            from: data
        )
    }

    // MARK: - Delete

    func deleteDictation(
        id: String
    ) async throws {

        guard let token =
            KeychainService.shared.loadToken()
        else {
            throw DictationServiceError.noToken
        }

        guard let url =
            URL(
                string: "/dictations/\(id)",
                relativeTo: baseURL
            )
        else {
            throw DictationServiceError.invalidURL
        }

        var request =
            URLRequest(url: url)

        request.httpMethod = "DELETE"

        request.setValue(
            "Bearer \(token)",
            forHTTPHeaderField: "Authorization"
        )

        let (_, response) =
            try await URLSession.shared.data(
                for: request
            )

        guard let httpResponse =
            response as? HTTPURLResponse
        else {
            throw DictationServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 204
        else {
            print(
                "Delete failed with status:",
                httpResponse.statusCode
            )

            throw DictationServiceError.requestFailed
        }

        print(
            "Deleted dictation:",
            id
        )
    }

}

enum DictationServiceError: Error {
    case noToken
    case invalidURL
    case invalidResponse
    case requestFailed
}
