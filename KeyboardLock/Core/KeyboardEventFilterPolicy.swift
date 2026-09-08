import CoreGraphics

enum KeyboardEventFilterPolicy {
    // Core Graphics does not expose NX_SYSDEFINED (raw event type 14) as a
    // named CGEventType case.
    static let systemDefinedEventType = CGEventType(rawValue: 14)!

    static func shouldBlock(type: CGEventType, systemDefinedSubtype: Int16? = nil) -> Bool {
        switch type {
        case .keyDown, .keyUp, .flagsChanged:
            return true
        default:
            guard type == systemDefinedEventType else { return false }

            // Subtypes 8 and 10 represent media/function controls and eject.
            // Other system-defined events include auxiliary mouse buttons and
            // lifecycle events, which must continue to pass through.
            return systemDefinedSubtype == 8 || systemDefinedSubtype == 10
        }
    }
}
