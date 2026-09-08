# Architecture

## Overview

KeyboardLock is a native menu-bar application for macOS 13 and newer. It uses a Core Graphics session event tap to suppress keyboard events while leaving mouse and trackpad input untouched. The app has no background service, kernel extension, network service, or privileged helper.

`AppState` is the main-actor coordinator. It owns the lock lifecycle, countdown, Accessibility status, Touch ID request, and presentation state. `KeyboardBlocker` owns the event tap. SwiftUI renders the menu and lock panel, while AppKit positions the floating `NSPanel` on the active display.

## Component diagram

```text
                         macOS
          ┌─────────────────────────────────┐
          │ Accessibility / TCC             │
          │ Core Graphics event stream      │
          │ LocalAuthentication / Touch ID  │
          └───────────┬─────────┬───────────┘
                      │         │
              keyboard events  │ biometric result
                      │         │
                ┌─────▼─────────▼─────┐
                │      AppState       │
                │ lock + timer state  │
                └───┬───────────┬─────┘
                    │           │
          ┌─────────▼──────┐  ┌─▼─────────────────┐
          │ KeyboardBlocker │  │ LockPanelController│
          │ CGEventTap      │  │ floating NSPanel   │
          └─────────┬──────┘  └─┬─────────────────┘
                    │           │
              pass or discard   ▼
                    │       LockScreenView
                    ▼
              other macOS apps

          MenuBarView ───────── observes AppState
```

## Component map

### Application lifecycle

- **Location:** `KeyboardLock/App/KeyboardLockApp.swift`
- **Responsibility:** creates the shared `AppState` and exposes `MenuBarView` through `MenuBarExtra`.
- **Depends on:** SwiftUI, AppKit, `AppState`, and `MenuBarView`.

### State coordinator

- **Location:** `KeyboardLock/App/AppState.swift`
- **Responsibility:** validates Accessibility trust, starts and stops blocking, manages the automatic timeout, requests Touch ID, and terminates safely.
- **Depends on:** `KeyboardBlocker`, `LockPanelController`, ApplicationServices, LocalAuthentication, and `UserDefaults`.
- **Persistent data:** only `lockDurationSeconds`, declared in the bundled privacy manifest.

### Keyboard filter

- **Locations:** `KeyboardLock/Core/KeyboardBlocker.swift` and `KeyboardLock/Core/KeyboardEventFilterPolicy.swift`
- **Responsibility:** creates a `cgSessionEventTap`, installs it on the main run loop, and decides which events to suppress.
- **Depends on:** Core Graphics and AppKit.
- **Thread safety:** an `NSLock` protects the callback-visible blocking flag.

### Unlock policy

- **Location:** `KeyboardLock/Core/UnlockPolicy.swift`
- **Responsibility:** defines the ten-second fallback hold duration in one place.

### User interface

- **Locations:** `KeyboardLock/UI/LockPanelController.swift` and `KeyboardLock/UI/Views/`
- **Responsibility:** renders the menu-bar commands and a floating, non-closable lock status panel on the display containing the pointer.
- **Depends on:** SwiftUI, AppKit, and `AppState`.

## Lock flow

1. The user selects **Lock keyboard**.
2. `AppState.lock()` refreshes Accessibility trust and stops if access is missing.
3. `KeyboardBlocker.start()` creates the event tap on first use, sets its protected blocking flag, and enables the tap.
4. `AppState` records an expiration date, starts a 250 ms display timer, and presents the lock panel.
5. The event callback discards `keyDown`, `keyUp`, and `flagsChanged` events.
6. System-defined subtype 8 and 10 events cover media/function controls and eject. Auxiliary mouse and unrelated system events pass through.
7. When the expiration time is reached, `AppState.unlock()` disables the event tap and removes the panel.

## Touch ID unlock flow

1. A mouse click on **Unlock with Touch ID** calls `AppState.unlockWithTouchID()`.
2. A new `LAContext` verifies that biometric device-owner authentication and Touch ID are available.
3. macOS displays and owns the biometric prompt.
4. The Secure Enclave and macOS perform fingerprint matching outside the app.
5. The callback receives only success or an error. Success calls `unlock()`.
6. Cancellation keeps the keyboard locked. Other errors are shown without removing the fallback paths.

KeyboardLock never receives fingerprint images, templates, or sensor data.

## Recovery paths

Three independent paths can restore input:

- Successful Touch ID authentication after an intentional click.
- A ten-second mouse hold on the fallback control.
- Expiration of the selected one-, three-, or five-minute safety timer.

Quitting calls `unlock()` before termination. If the process crashes, macOS removes its event tap with the process. If macOS disables the tap because the callback times out or user input disables it, the callback re-enables it while the app is still in the locked state.

## Module dependency graph

```text
KeyboardLockApp
└── AppState
    ├── KeyboardBlocker
    │   └── KeyboardEventFilterPolicy
    ├── LockPanelController
    │   └── LockScreenView
    └── LocalAuthentication + ApplicationServices

MenuBarView ──> AppState
LockScreenView ──> AppState + UnlockPolicy
```

There are no circular module dependencies and no third-party runtime dependencies.

## Key architectural decisions

### Session event tap instead of a driver

A session-level event tap is sufficient for a cleaning utility and avoids kernel extensions, system extensions, root privileges, and hardware manipulation. The trade-off is that Accessibility permission is mandatory and some hardware-level keys, especially the power button, remain outside the app's control.

### Mouse input always passes through

Mouse and trackpad events are intentionally absent from the event mask. This guarantees that every unlock control remains reachable while keyboard input is suppressed.

### Biometric-only policy

Touch ID uses `deviceOwnerAuthenticationWithBiometrics`, not a passcode fallback. A password cannot be typed while the keyboard filter is active, so a biometric-only request prevents an unusable prompt. The mouse hold and safety timer provide non-keyboard recovery.

### Main-actor state ownership

UI and lifecycle state stay on the main actor. The event-tap callback reads only a small lock-protected flag, minimizing callback work and reducing the chance that macOS disables the tap for taking too long.

### No telemetry or networking

The utility has no operational need for a server. Omitting networking and analytics keeps the privacy model auditable directly from the source tree.

## Testing strategy

`KeyboardLockTests` covers deterministic event-filter decisions and the fallback hold duration. System-level Accessibility and Touch ID interactions require manual testing on physical Mac hardware because CI cannot grant TCC permissions or emulate a fingerprint.

Before merging changes that affect input handling, complete both automated checks and the manual safety checklist in [CONTRIBUTING.md](../CONTRIBUTING.md).
