# KeyboardLock — behavior specification

## Goal

Provide a tiny macOS menu bar utility that temporarily ignores keyboard input so the user can clean a MacBook keyboard without triggering applications or system shortcuts.

## Supported environment

- macOS 13 Ventura or newer
- Apple silicon and Intel Macs
- Built-in and external keyboards whose input reaches the macOS Quartz event stream

## User flow

1. The user launches KeyboardLock and sees a keyboard icon in the menu bar.
2. On first launch, KeyboardLock asks for Accessibility access and explains where to enable it.
3. The user chooses **Lock keyboard**.
4. Once locked, keyboard events are discarded and a floating status panel appears.
5. The user unlocks by either:
   - clicking **Unlock with Touch ID** and authenticating with a registered fingerprint;
   - holding the on-screen fallback control for ten seconds; or
   - waiting for the safety timer to expire.
6. The app immediately restores normal keyboard delivery and hides the panel.

## Safety requirements

- Mouse and trackpad events must never be blocked.
- Touch ID authentication must require a deliberate mouse click, so wiping the sensor cannot unlock the keyboard accidentally.
- The ten-second mouse hold and safety timer must remain available if Touch ID is unavailable or temporarily locked out.
- The lock must automatically expire. The default is three minutes; one, three, and five minutes are available.
- Quitting or crashing the app must release the event tap, restoring input.
- If macOS disables the event tap because its callback timed out, the app must re-enable it.
- The lock screen must state the remaining time and every available unlock method.

## Technical design

- SwiftUI menu bar app with an AppKit `NSPanel` for the lock status UI.
- A Core Graphics active session event tap filters `keyDown`, `keyUp`, `flagsChanged`, and system-defined media/function-key events.
- While locked, the callback returns `nil` for those events so macOS does not deliver them further.
- Accessibility trust is checked with `AXIsProcessTrustedWithOptions`.
- Touch ID is requested with `LocalAuthentication` and the biometric-only device-owner policy. The app receives only success or failure.
- The app is an accessory (`LSUIElement`) and does not show a Dock icon.
- Public source does not contain a development team. Maintainers and contributors provide their own signing identity when they need stable Accessibility trust across rebuilds.

## Explicit non-goals

- Blocking the power button.
- Disabling keyboard hardware or kernel drivers.
- Password-protecting the computer or replacing the macOS lock screen.
- Mac App Store distribution.

## Privacy requirements

- Ordinary keyboard events must not be inspected for character content or key codes.
- Events must not be logged, buffered, persisted, counted, analyzed, or transmitted.
- Touch ID must use Apple's `LocalAuthentication` framework. The app may receive only the authentication result and must not persist it.
- The app must not include analytics, telemetry, advertising, or networking without an explicit public design review and an update to `docs/PRIVACY.md`.
- The selected safety-timer duration is the only preference persisted by the current design.
