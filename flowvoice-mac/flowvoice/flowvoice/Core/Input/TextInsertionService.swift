import AppKit
import ApplicationServices
import Foundation

@MainActor
final class TextInsertionService {

    static let shared = TextInsertionService()

    private init() {}

    func insertText(_ text: String) {

        let cleanedText = text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanedText.isEmpty else {
            return
        }

        guard AccessibilityPermissionService
            .shared
            .isTrusted()
        else {
            AccessibilityPermissionService
                .shared
                .requestPermission()

            print(
                "FlowVoice: Accessibility permission missing"
            )

            return
        }

        print(
            "FlowVoice attempting direct insertion:",
            cleanedText
        )

        if insertUsingAccessibility(
            cleanedText
        ) {
            print(
                "FlowVoice direct insertion succeeded"
            )

            return
        }

        print(
            "Direct insertion unavailable — using clipboard fallback"
        )

        insertUsingClipboard(
            cleanedText
        )
    }

    // MARK: - Accessibility insertion

    private func insertUsingAccessibility(
        _ text: String
    ) -> Bool {

        let systemWideElement =
            AXUIElementCreateSystemWide()

        var focusedValue: CFTypeRef?

        let focusedResult =
            AXUIElementCopyAttributeValue(
                systemWideElement,
                kAXFocusedUIElementAttribute
                    as CFString,
                &focusedValue
            )

        guard focusedResult == .success else {

            print(
                "Could not get focused element:",
                focusedResult.rawValue
            )

            return false
        }

        guard let focusedValue else {

            print(
                "No focused Accessibility element"
            )

            return false
        }

        let focusedElement =
            unsafeBitCast(
                focusedValue,
                to: AXUIElement.self
            )

        // This replaces the current selection.
        // If nothing is selected, it inserts at the cursor.
        let result =
            AXUIElementSetAttributeValue(
                focusedElement,
                kAXSelectedTextAttribute
                    as CFString,
                text as CFTypeRef
            )

        if result == .success {
            return true
        }

        print(
            "Selected text insertion failed:",
            result.rawValue
        )

        return false
    }

    // MARK: - Clipboard fallback

    private func insertUsingClipboard(
        _ text: String
    ) {

        let pasteboard =
            NSPasteboard.general

        let previousText =
            pasteboard.string(
                forType: .string
            )

        pasteboard.clearContents()

        guard pasteboard.setString(
            text,
            forType: .string
        ) else {

            print(
                "FlowVoice: Could not write clipboard"
            )

            return
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.12
        ) {
            self.simulatePaste()

            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.8
            ) {
                self.restoreClipboard(
                    previousText
                )
            }
        }
    }

    private func simulatePaste() {

        guard let source =
            CGEventSource(
                stateID: .hidSystemState
            )
        else {
            return
        }

        let keyV: CGKeyCode = 9

        guard
            let keyDown = CGEvent(
                keyboardEventSource: source,
                virtualKey: keyV,
                keyDown: true
            ),
            let keyUp = CGEvent(
                keyboardEventSource: source,
                virtualKey: keyV,
                keyDown: false
            )
        else {
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(
            tap: .cghidEventTap
        )

        usleep(
            20_000
        )

        keyUp.post(
            tap: .cghidEventTap
        )

        print(
            "FlowVoice clipboard paste sent"
        )
    }

    private func restoreClipboard(
        _ previousText: String?
    ) {

        guard let previousText else {
            return
        }

        let pasteboard =
            NSPasteboard.general

        pasteboard.clearContents()

        pasteboard.setString(
            previousText,
            forType: .string
        )
    }
}
