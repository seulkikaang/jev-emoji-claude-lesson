import ApplicationServices

/// Small read-only wrappers around the macOS Accessibility C API.
enum AXElement {
    /// Short timeout so an unresponsive app cannot freeze the shortcut.
    static let messagingTimeout: Float = 0.4

    /// The input element that has keyboard focus inside the app with `pid`.
    static func focusedElement(ofPID pid: pid_t) -> (error: AXError, element: AXUIElement?) {
        let appElement = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(appElement, messagingTimeout)
        let (error, value) = copyAttribute(appElement, kAXFocusedUIElementAttribute)
        guard error == .success, let value, CFGetTypeID(value) == AXUIElementGetTypeID() else {
            return (error == .success ? .noValue : error, nil)
        }
        let element = value as! AXUIElement
        AXUIElementSetMessagingTimeout(element, messagingTimeout)
        return (.success, element)
    }

    static func isSecureField(_ element: AXUIElement) -> Bool {
        string(element, kAXSubroleAttribute) == kAXSecureTextFieldSubrole
            || string(element, kAXRoleAttribute) == "AXSecureTextField"
    }

    /// true: the field accepts text, false: it does not, nil: macOS could not tell.
    static func isEditable(_ element: AXUIElement) -> Bool? {
        let selectedText = isSettable(element, kAXSelectedTextAttribute)
        let value = isSettable(element, kAXValueAttribute)
        if selectedText == true || value == true { return true }
        if selectedText == nil && value == nil { return nil }
        return false
    }

    static func isSettable(_ element: AXUIElement, _ attribute: String) -> Bool? {
        var settable = DarwinBoolean(false)
        let error = AXUIElementIsAttributeSettable(element, attribute as CFString, &settable)
        guard error == .success else { return nil }
        return settable.boolValue
    }

    static func isSameElement(_ lhs: AXUIElement, _ rhs: AXUIElement) -> Bool {
        CFEqual(lhs, rhs)
    }

    static func string(_ element: AXUIElement, _ attribute: String) -> String? {
        let (error, value) = copyAttribute(element, attribute)
        guard error == .success else { return nil }
        return value as? String
    }

    static func int(_ element: AXUIElement, _ attribute: String) -> Int? {
        let (error, value) = copyAttribute(element, attribute)
        guard error == .success else { return nil }
        return (value as? NSNumber)?.intValue
    }

    static func selectedRange(_ element: AXUIElement) -> CFRange? {
        let (error, value) = copyAttribute(element, kAXSelectedTextRangeAttribute)
        guard error == .success, let value, CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        let axValue = value as! AXValue
        var range = CFRange()
        guard AXValueGetType(axValue) == .cfRange, AXValueGetValue(axValue, .cfRange, &range) else { return nil }
        return range
    }

    static func string(_ element: AXUIElement, in range: CFRange) -> String? {
        var mutableRange = range
        guard let rangeValue = AXValueCreate(.cfRange, &mutableRange) else { return nil }
        var result: CFTypeRef?
        let error = AXUIElementCopyParameterizedAttributeValue(
            element, kAXStringForRangeParameterizedAttribute as CFString, rangeValue, &result
        )
        guard error == .success else { return nil }
        return result as? String
    }

    private static func copyAttribute(_ element: AXUIElement, _ attribute: String) -> (AXError, CFTypeRef?) {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        return (error, value)
    }
}
