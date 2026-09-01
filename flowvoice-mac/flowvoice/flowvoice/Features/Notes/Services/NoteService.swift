import Foundation

private struct CreateNoteBody: Codable {

    let title: String
    let transcript: String
    let durationSeconds: Int?
    let segments: [NoteSpeakerSegment]

    enum CodingKeys: String, CodingKey {
        case title
        case transcript
        case durationSeconds = "duration_seconds"
        case segments
    }
}

@MainActor
final class NoteService {

    static let shared = NoteService()

    private init() {}
    

    private var baseURL: URL {
        URL(string: APIConfig.baseURL)!
    }
    

    // MARK: - Fetch Notes

    func fetchNotes() async throws -> [Note] {

        guard let token =
            KeychainService.shared.loadToken()
        else {
            throw NoteServiceError.noToken
        }

        guard let url =
            URL(
                string: "/notes",
                relativeTo: baseURL
            )
        else {
            throw NoteServiceError.invalidURL
        }

        var request =
            URLRequest(url: url)

        request.httpMethod = "GET"

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
            throw NoteServiceError.invalidResponse
        }

        guard
            httpResponse.statusCode == 200
        else {
            print(
                "Fetch notes failed:",
                httpResponse.statusCode
            )

            if let body =
                String(
                    data: data,
                    encoding: .utf8
                ) {

                print(
                    "Backend response:",
                    body
                )
            }

            throw NoteServiceError.requestFailed
        }

        return try JSONDecoder().decode(
            [Note].self,
            from: data
        )
    }

    // MARK: - Create Note

    func createNote(
        title: String,
        transcript: String,
        durationSeconds: Int?,
        segments: [NoteSpeakerSegment]
    ) async throws -> Note {

        guard let token =
            KeychainService.shared.loadToken()
        else {
            throw NoteServiceError.noToken
        }

        guard let url =
            URL(
                string: "/notes",
                relativeTo: baseURL
            )
        else {
            throw NoteServiceError.invalidURL
        }

        var request =
            URLRequest(url: url)

        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField:
                "Content-Type"
        )

        request.setValue(
            "Bearer \(token)",
            forHTTPHeaderField:
                "Authorization"
        )

        let body =
            CreateNoteBody(
                title: title,
                transcript: transcript,
                durationSeconds:
                    durationSeconds,
                segments: segments
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
            throw NoteServiceError.invalidResponse
        }

        guard
            httpResponse.statusCode == 201
        else {

            print(
                "Create note failed:",
                httpResponse.statusCode
            )

            if let body =
                String(
                    data: data,
                    encoding: .utf8
                ) {

                print(
                    "Backend response:",
                    body
                )
            }

            throw NoteServiceError.requestFailed
        }

        return try JSONDecoder().decode(
            Note.self,
            from: data
        )
    }

    // MARK: - Delete Note

    func deleteNote(
        id: String
    ) async throws {

        guard let token =
            KeychainService.shared.loadToken()
        else {
            throw NoteServiceError.noToken
        }

        guard let url =
            URL(
                string:
                    "/notes/\(id)",
                relativeTo: baseURL
            )
        else {
            throw NoteServiceError.invalidURL
        }

        var request =
            URLRequest(url: url)

        request.httpMethod =
            "DELETE"

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
            throw NoteServiceError.invalidResponse
        }

        guard
            httpResponse.statusCode == 204
        else {

            print(
                "Delete note failed:",
                httpResponse.statusCode
            )

            if let body =
                String(
                    data: data,
                    encoding: .utf8
                ) {

                print(
                    "Backend response:",
                    body
                )
            }

            throw NoteServiceError.requestFailed
        }
    }

    // MARK: - Summarize Note

    func summarizeNote(
        id: String
    ) async throws -> Note {

        guard let token =
            KeychainService.shared.loadToken()
        else {
            throw NoteServiceError.noToken
        }

        guard let url =
            URL(
                string:
                    "/notes/\(id)/summarize",
                relativeTo: baseURL
            )
        else {
            throw NoteServiceError.invalidURL
        }

        var request =
            URLRequest(url: url)

        request.httpMethod =
            "POST"

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
            throw NoteServiceError.invalidResponse
        }

        guard
            httpResponse.statusCode == 200
        else {

            print(
                "Summarize note failed:",
                httpResponse.statusCode
            )

            if let body =
                String(
                    data: data,
                    encoding: .utf8
                ) {

                print(
                    "Backend response:",
                    body
                )
            }

            throw NoteServiceError.requestFailed
        }

        return try JSONDecoder().decode(
            Note.self,
            from: data
        )
    }
}

enum NoteServiceError: Error {
    case noToken
    case invalidURL
    case invalidResponse
    case requestFailed
}
