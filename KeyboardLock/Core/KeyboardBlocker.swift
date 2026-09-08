import AppKit
import CoreGraphics
import Foundation

enum KeyboardBlockerError: LocalizedError {
    case eventTapUnavailable

    var errorDescription: String? {
        switch self {
        case .eventTapUnavailable:
            return "KeyboardLock could not start the keyboard filter. Check Accessibility permission and try again."
        }
    }
}

final class KeyboardBlocker {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isBlocking = false
    private let stateLock = NSLock()

    deinit {
        stop()
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
    }

    func start() throws {
        if eventTap == nil {
            try createEventTap()
        }

        stateLock.lock()
        isBlocking = true
        stateLock.unlock()

        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: true)
        }
    }

    func stop() {
        stateLock.lock()
        isBlocking = false
        stateLock.unlock()

        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
    }

    private func createEventTap() throws {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
            | CGEventMask(1 << CGEventType.keyUp.rawValue)
            | CGEventMask(1 << CGEventType.flagsChanged.rawValue)
            | CGEventMask(1 << KeyboardEventFilterPolicy.systemDefinedEventType.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: keyboardEventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            throw KeyboardBlockerError.eventTapUnavailable
        }

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            CFMachPortInvalidate(tap)
            throw KeyboardBlockerError.eventTapUnavailable
        }

        eventTap = tap
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
    }

    fileprivate func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            stateLock.lock()
            let shouldReenable = isBlocking
            stateLock.unlock()

            if shouldReenable, let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        stateLock.lock()
        let shouldBlock = isBlocking
        stateLock.unlock()

        guard shouldBlock else {
            return Unmanaged.passUnretained(event)
        }

        let subtype = type == KeyboardEventFilterPolicy.systemDefinedEventType
            ? NSEvent(cgEvent: event)?.subtype.rawValue
            : nil

        return KeyboardEventFilterPolicy.shouldBlock(
            type: type,
            systemDefinedSubtype: subtype
        ) ? nil : Unmanaged.passUnretained(event)
    }
}

private let keyboardEventTapCallback: CGEventTapCallBack = { _, type, event, userInfo in
    guard let userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let blocker = Unmanaged<KeyboardBlocker>.fromOpaque(userInfo).takeUnretainedValue()
    return blocker.handle(type: type, event: event)
}
