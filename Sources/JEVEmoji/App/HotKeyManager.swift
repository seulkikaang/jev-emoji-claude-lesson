import Carbon.HIToolbox

enum HotKeyError: Error {
    case handlerInstallFailed(OSStatus)
    case registrationFailed(OSStatus)
}

/// Global shortcut through Carbon's RegisterEventHotKey.
/// It works while other apps are in front and needs no privacy permission.
final class HotKeyManager {
    private static let signature: OSType = 0x4A45_5645 // "JEVE"

    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    /// Defaults to Option+Command+E.
    func register(
        keyCode: UInt32 = UInt32(kVK_ANSI_E),
        modifiers: UInt32 = UInt32(optionKey | cmdKey)
    ) throws {
        unregister()

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let context = Unmanaged.passUnretained(self).toOpaque()
        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else { return OSStatus(eventNotHandledErr) }
                Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue().action()
                return OSStatus(noErr)
            },
            1,
            &eventSpec,
            context,
            &handlerRef
        )
        guard installStatus == OSStatus(noErr) else { throw HotKeyError.handlerInstallFailed(installStatus) }

        let hotKeyID = EventHotKeyID(signature: Self.signature, id: 1)
        let registerStatus = RegisterEventHotKey(
            keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef
        )
        guard registerStatus == OSStatus(noErr) else {
            unregister()
            throw HotKeyError.registrationFailed(registerStatus)
        }
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let handlerRef {
            RemoveEventHandler(handlerRef)
            self.handlerRef = nil
        }
    }

    deinit {
        unregister()
    }
}
