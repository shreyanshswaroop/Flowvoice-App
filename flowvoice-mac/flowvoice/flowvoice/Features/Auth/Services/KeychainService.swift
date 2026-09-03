import Foundation
import Security

final class KeychainService {

    static let shared = KeychainService()

    private init() {}

    private let service = "flow.flowvoice"
    private let tokenAccount = "flowvoice.auth.token"

    // MARK: - Save Token

    @discardableResult
    func saveToken(_ token: String) -> Bool {

        guard let data = token.data(using: .utf8) else {
            print("FlowVoice Keychain: failed to convert token to Data")
            return false
        }

        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenAccount
        ]

        // Remove old token first.
        let deleteStatus = SecItemDelete(
            baseQuery as CFDictionary
        )

        if deleteStatus != errSecSuccess &&
            deleteStatus != errSecItemNotFound {

            print(
                "FlowVoice Keychain delete-before-save failed:",
                deleteStatus,
                errorMessage(for: deleteStatus)
            )
        }

        var attributes = baseQuery

        attributes[
            kSecValueData as String
        ] = data

        attributes[
            kSecAttrAccessible as String
        ] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(
            attributes as CFDictionary,
            nil
        )

        if status == errSecSuccess {

            print(
                "FlowVoice auth token saved to Keychain"
            )

            return true
        }

        print(
            "FlowVoice Keychain save failed:",
            status,
            errorMessage(for: status)
        )

        return false
    }

    // MARK: - Load Token

    func loadToken() -> String? {

        let query: [String: Any] = [
            kSecClass as String:
                kSecClassGenericPassword,

            kSecAttrService as String:
                service,

            kSecAttrAccount as String:
                tokenAccount,

            kSecReturnData as String:
                true,

            kSecMatchLimit as String:
                kSecMatchLimitOne
        ]

        var result: AnyObject?

        let status = SecItemCopyMatching(
            query as CFDictionary,
            &result
        )

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {

            print(
                "FlowVoice Keychain load failed:",
                status,
                errorMessage(for: status)
            )

            return nil
        }

        guard let data = result as? Data else {

            print(
                "FlowVoice Keychain: stored value is not Data"
            )

            return nil
        }

        guard let token = String(
            data: data,
            encoding: .utf8
        ) else {

            print(
                "FlowVoice Keychain: failed to decode stored token"
            )

            return nil
        }

        return token
    }

    // MARK: - Delete Token

    func deleteToken() {

        let query: [String: Any] = [
            kSecClass as String:
                kSecClassGenericPassword,

            kSecAttrService as String:
                service,

            kSecAttrAccount as String:
                tokenAccount
        ]

        let status = SecItemDelete(
            query as CFDictionary
        )

        if status == errSecSuccess {

            print(
                "FlowVoice auth token removed from Keychain"
            )

            return
        }

        if status == errSecItemNotFound {
            return
        }

        print(
            "FlowVoice Keychain delete failed:",
            status,
            errorMessage(for: status)
        )
    }

    // MARK: - Error Description

    private func errorMessage(
        for status: OSStatus
    ) -> String {

        if let message =
            SecCopyErrorMessageString(
                status,
                nil
            ) as String? {

            return message
        }

        return "Unknown Keychain error"
    }
}
