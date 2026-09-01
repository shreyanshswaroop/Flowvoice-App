import Foundation
import Security

final class KeychainService {

    static let shared = KeychainService()

    private init() {}

    private let service = "flow.flowvoice"
    private let tokenAccount = "flowvoice.auth.token"

    func saveToken(_ token: String) -> Bool {
        guard let data = token.data(using: .utf8) else {
            return false
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenAccount
        ]

        SecItemDelete(query as CFDictionary)

        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenAccount,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(
            attributes as CFDictionary,
            nil
        )

        if status == errSecSuccess {
            print("FlowVoice auth token saved to Keychain")
            return true
        }

        print(
            "FlowVoice Keychain save failed:",
            status
        )

        return false
    }

    func loadToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?

        let status = SecItemCopyMatching(
            query as CFDictionary,
            &result
        )

        guard
            status == errSecSuccess,
            let data = result as? Data,
            let token = String(
                data: data,
                encoding: .utf8
            )
        else {
            return nil
        }

        return token
    }

    func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenAccount
        ]

        SecItemDelete(
            query as CFDictionary
        )

        print("FlowVoice auth token removed from Keychain")
    }
}
