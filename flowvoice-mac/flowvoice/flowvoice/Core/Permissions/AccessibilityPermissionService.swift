import Foundation
import ApplicationServices

final class AccessibilityPermissionService {

    static let shared = AccessibilityPermissionService()

    private init() {}

    func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    @discardableResult
    func requestPermission() -> Bool {
        let options: NSDictionary = [
            kAXTrustedCheckOptionPrompt
                .takeUnretainedValue() as String: true
        ]

        let trusted = AXIsProcessTrustedWithOptions(
            options
        )

        print(
            "Accessibility trusted:",
            trusted
        )

        return trusted
    }
}
