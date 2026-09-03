import Foundation

@MainActor
final class DictionaryService {

    static let shared =
        DictionaryService()

    private init() {}

    private var baseURL: URL {
        URL(string: APIConfig.baseURL)!
    }

    // MARK: ============================================
    // MARK: FETCH ENTRIES
    // MARK: ============================================

    func fetchEntries()
        async throws
        -> [DictionaryEntry] {

        let request =
            try authorizedRequest(
                path:
                    "/dictionary",
                method:
                    "GET"
            )

        let (data, response) =
            try await URLSession
                .shared
                .data(
                    for:
                        request
                )

        try validate(
            response,
            data:
                data
        )

        return try JSONDecoder()
            .decode(
                [DictionaryEntry].self,
                from:
                    data
            )
    }

    // MARK: ============================================
    // MARK: CREATE
    // MARK: ============================================

    func createEntry(
        type: DictionaryEntryType,
        value: String,
        replacement: String? = nil,
        scope: DictionaryScope = .personal
    ) async throws
        -> DictionaryEntry {

        var request =
            try authorizedRequest(
                path:
                    "/dictionary",
                method:
                    "POST"
            )

        request.setValue(
            "application/json",
            forHTTPHeaderField:
                "Content-Type"
        )

        let body =
            CreateDictionaryBody(
                type:
                    type.rawValue,
                value:
                    value,
                replacement:
                    replacement,
                scope:
                    scope.rawValue
            )

        request.httpBody =
            try JSONEncoder()
                .encode(
                    body
                )

        let (data, response) =
            try await URLSession
                .shared
                .data(
                    for:
                        request
                )

        try validate(
            response,
            data:
                data
        )

        return try JSONDecoder()
            .decode(
                DictionaryEntry.self,
                from:
                    data
            )
    }

    // MARK: ============================================
    // MARK: UPDATE
    // MARK: ============================================

    func updateEntry(
        id: String,
        type: DictionaryEntryType,
        value: String,
        replacement: String?,
        scope: DictionaryScope
    ) async throws
        -> DictionaryEntry {

        var request =
            try authorizedRequest(
                path:
                    "/dictionary/\(id)",
                method:
                    "PATCH"
            )

        request.setValue(
            "application/json",
            forHTTPHeaderField:
                "Content-Type"
        )

        let body =
            UpdateDictionaryBody(
                type:
                    type.rawValue,
                value:
                    value,
                replacement:
                    replacement,
                scope:
                    scope.rawValue
            )

        request.httpBody =
            try JSONEncoder()
                .encode(
                    body
                )

        let (data, response) =
            try await URLSession
                .shared
                .data(
                    for:
                        request
                )

        try validate(
            response,
            data:
                data
        )

        return try JSONDecoder()
            .decode(
                DictionaryEntry.self,
                from:
                    data
            )
    }

    // MARK: ============================================
    // MARK: DELETE
    // MARK: ============================================

    func deleteEntry(
        id: String
    ) async throws {

        let request =
            try authorizedRequest(
                path:
                    "/dictionary/\(id)",
                method:
                    "DELETE"
            )

        let (data, response) =
            try await URLSession
                .shared
                .data(
                    for:
                        request
                )

        try validate(
            response,
            data:
                data
        )
    }

    // MARK: ============================================
    // MARK: SUGGESTIONS
    // MARK: ============================================

    func fetchSuggestions()
        async throws
        -> [DictionaryEntry] {

        let request =
            try authorizedRequest(
                path:
                    "/dictionary/suggestions",
                method:
                    "GET"
            )

        let (data, response) =
            try await URLSession
                .shared
                .data(
                    for:
                        request
                )

        try validate(
            response,
            data:
                data
        )

        return try JSONDecoder()
            .decode(
                [DictionaryEntry].self,
                from:
                    data
            )
    }

    // MARK: - Accept Suggestion

    func acceptSuggestion(
        id: String
    ) async throws
        -> DictionaryEntry {

        let request =
            try authorizedRequest(
                path:
                    "/dictionary/suggestions/\(id)/accept",
                method:
                    "POST"
            )

        let (data, response) =
            try await URLSession
                .shared
                .data(
                    for:
                        request
                )

        try validate(
            response,
            data:
                data
        )

        return try JSONDecoder()
            .decode(
                DictionaryEntry.self,
                from:
                    data
            )
    }

    // MARK: - Reject Suggestion

    func rejectSuggestion(
        id: String
    ) async throws {

        let request =
            try authorizedRequest(
                path:
                    "/dictionary/suggestions/\(id)",
                method:
                    "DELETE"
            )

        let (data, response) =
            try await URLSession
                .shared
                .data(
                    for:
                        request
                )

        try validate(
            response,
            data:
                data
        )
    }

    // MARK: ============================================
    // MARK: DEEPGRAM KEYTERMS
    // MARK: ============================================

    func fetchKeyterms()
        async throws
        -> [String] {

        let entries =
            try await fetchEntries()

        return entries
            .filter {
                $0.canSendToDeepgram
            }
            .map {
                $0.value
            }
            .prefix(100)
            .map {
                $0
            }
    }

    // MARK: ============================================
    // MARK: REPLACEMENT RULES
    // MARK: ============================================

    func fetchReplacementRules()
        async throws
        -> [DictionaryEntry] {

        let entries =
            try await fetchEntries()

        return entries.filter {

            $0.type == .replacement
            &&
            $0.active
            &&
            $0.source == .manual
            &&
            $0.replacement != nil
        }
    }

    // MARK: - Apply Replacements

    func applyReplacements(
        to text: String
    ) async -> String {

        guard
            !text.isEmpty
        else {
            return text
        }

        do {

            let rules =
                try await fetchReplacementRules()

            var output =
                text

            for rule in rules {

                guard let replacement =
                    rule.replacement?
                        .trimmingCharacters(
                            in:
                                .whitespacesAndNewlines
                        ),
                    !replacement.isEmpty
                else {
                    continue
                }

                let source =
                    rule.value
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )

                guard
                    !source.isEmpty
                else {
                    continue
                }

                output =
                    replaceWholePhrase(
                        source,
                        with:
                            replacement,
                        in:
                            output
                    )
            }

            return output

        } catch {

            // Replacement failure should never
            // stop normal dictation.

            print(
                "Could not load dictionary replacements:",
                error
            )

            return text
        }
    }

    // MARK: - Replacement Helper

    private func replaceWholePhrase(
        _ source: String,
        with replacement: String,
        in text: String
    ) -> String {

        let escaped =
            NSRegularExpression
                .escapedPattern(
                    for:
                        source
                )

        let pattern =
            "(?i)(?<![\\p{L}\\p{N}_])\(escaped)(?![\\p{L}\\p{N}_])"

        guard let regex =
            try? NSRegularExpression(
                pattern:
                    pattern
            )
        else {

            return text
        }

        let range =
            NSRange(
                text.startIndex...,
                in:
                    text
            )

        return regex
            .stringByReplacingMatches(
                in:
                    text,
                options:
                    [],
                range:
                    range,
                withTemplate:
                    NSRegularExpression
                        .escapedTemplate(
                            for:
                                replacement
                        )
            )
    }

    // MARK: ============================================
    // MARK: AUTH REQUEST
    // MARK: ============================================

    private func authorizedRequest(
        path: String,
        method: String
    ) throws -> URLRequest {

        guard let token =
            KeychainService
                .shared
                .loadToken()
        else {

            throw DictionaryServiceError
                .noToken
        }

        guard let url =
            URL(
                string:
                    path,
                relativeTo:
                    baseURL
            )
        else {

            throw DictionaryServiceError
                .invalidURL
        }

        var request =
            URLRequest(
                url:
                    url
            )

        request.httpMethod =
            method

        request.setValue(
            "Bearer \(token)",
            forHTTPHeaderField:
                "Authorization"
        )

        return request
    }

    // MARK: ============================================
    // MARK: VALIDATE
    // MARK: ============================================

    private func validate(
        _ response: URLResponse,
        data: Data
    ) throws {

        guard let http =
            response
                as? HTTPURLResponse
        else {

            throw DictionaryServiceError
                .invalidResponse
        }

        guard
            (200...299)
                .contains(
                    http.statusCode
                )
        else {

            if let body =
                String(
                    data:
                        data,
                    encoding:
                        .utf8
                ) {

                print(
                    "Dictionary backend:",
                    body
                )
            }

            switch http.statusCode {

            case 400:

                throw DictionaryServiceError
                    .badRequest

            case 401:

                throw DictionaryServiceError
                    .unauthorized

            case 404:

                throw DictionaryServiceError
                    .notFound

            case 409:

                throw DictionaryServiceError
                    .duplicate

            default:

                throw DictionaryServiceError
                    .requestFailed
            }
        }
    }
}


// MARK: ================================================
// MARK: REQUEST BODIES
// MARK: ================================================

private struct CreateDictionaryBody:
    Codable {

    let type: String
    let value: String
    let replacement: String?
    let scope: String
}


private struct UpdateDictionaryBody:
    Codable {

    let type: String
    let value: String
    let replacement: String?
    let scope: String
}


// MARK: ================================================
// MARK: ERRORS
// MARK: ================================================

enum DictionaryServiceError:
    Error {

    case noToken
    case invalidURL
    case invalidResponse

    case badRequest
    case unauthorized
    case notFound
    case duplicate
    case requestFailed
}
