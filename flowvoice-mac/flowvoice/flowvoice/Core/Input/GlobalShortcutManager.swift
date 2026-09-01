import Foundation
import Carbon

final class GlobalShortcutManager {

    static let shared = GlobalShortcutManager()

    var onKeyDown: (() -> Void)?
    var onKeyUp: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    private let hotKeyInternalID: UInt32 = 1

    private var isPressed = false

    private init() {}

    func start() {

        installHandler()
        registerHotKey()
    }

    deinit {

        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }

        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }

    // MARK: - Register

    private func registerHotKey() {

        if hotKeyRef != nil {
            return
        }

        var hotKeyID = EventHotKeyID(
            signature: fourCharCode("FLVO"),
            id: hotKeyInternalID
        )

        let status = RegisterEventHotKey(
            49, // Space
            UInt32(optionKey),
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        if status != noErr {
            print(
                "Could not register FlowVoice shortcut:",
                status
            )
        }
    }

    // MARK: - Event Handler

    private func installHandler() {

        if eventHandler != nil {
            return
        }

        var eventTypes = [

            EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            ),

            EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyReleased)
            )
        ]

        let status = InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, event, userData in

                guard
                    let event,
                    let userData
                else {
                    return noErr
                }

                let manager =
                    Unmanaged<GlobalShortcutManager>
                        .fromOpaque(userData)
                        .takeUnretainedValue()

                var hotKeyID =
                    EventHotKeyID()

                let parameterStatus =
                    GetEventParameter(
                        event,
                        EventParamName(
                            kEventParamDirectObject
                        ),
                        EventParamType(
                            typeEventHotKeyID
                        ),
                        nil,
                        MemoryLayout<EventHotKeyID>.size,
                        nil,
                        &hotKeyID
                    )

                guard
                    parameterStatus == noErr
                else {
                    return parameterStatus
                }

                guard
                    hotKeyID.id ==
                        manager.hotKeyInternalID
                else {
                    return noErr
                }

                let kind =
                    GetEventKind(event)

                DispatchQueue.main.async {

                    // MARK: Key Down

                    if kind ==
                        UInt32(
                            kEventHotKeyPressed
                        ) {

                        guard !manager.isPressed else {
                            return
                        }

                        manager.isPressed = true

                        manager.onKeyDown?()
                    }

                    // MARK: Key Up

                    else if kind ==
                        UInt32(
                            kEventHotKeyReleased
                        ) {

                        guard manager.isPressed else {
                            return
                        }

                        manager.isPressed = false

                        manager.onKeyUp?()
                    }
                }

                return noErr
            },
            2,
            &eventTypes,
            Unmanaged
                .passUnretained(self)
                .toOpaque(),
            &eventHandler
        )

        if status != noErr {

            print(
                "Could not install FlowVoice shortcut handler:",
                status
            )
        }
    }

    // MARK: - Four Character Code

    private func fourCharCode(
        _ string: String
    ) -> FourCharCode {

        string.utf8.reduce(0) {
            ($0 << 8) + FourCharCode($1)
        }
    }
}
