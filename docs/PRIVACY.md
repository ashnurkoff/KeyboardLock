# Privacy

KeyboardLock is designed to perform one local task without collecting user data.

## Summary

- No keystrokes or typed content are recorded.
- No fingerprints or biometric records are accessible to the app.
- No analytics, telemetry, advertising, crash-reporting SDK, or tracking is included.
- No data is sent over a network. KeyboardLock contains no networking code.
- The only persisted app preference is the selected safety-timer duration.

## Keyboard events

macOS delivers selected keyboard events to a Core Graphics event-tap callback while KeyboardLock is running. When the lock is active, the callback returns `nil` so macOS does not deliver those events to other applications.

KeyboardLock does not read character content or key codes from ordinary keyboard events. It does not log, buffer, count, analyze, persist, or transmit them. For legacy system-defined events, the code reads only the event subtype needed to distinguish media/function controls from unrelated system and auxiliary mouse events.

When the lock is inactive, the event tap is disabled.

## Touch ID

KeyboardLock uses Apple's `LocalAuthentication` framework with the biometric-only device-owner policy.

Fingerprint matching is performed by macOS and the Secure Enclave. KeyboardLock cannot access:

- fingerprint images;
- fingerprint templates;
- raw Touch ID sensor data;
- which registered finger was used.

The app receives only whether the authentication request succeeded or an error occurred. It does not store that result.

Touch ID is requested only after the user deliberately clicks the unlock button. Contact with the Touch ID sensor while cleaning cannot initiate an authentication request by itself.

## Accessibility permission

macOS requires Accessibility permission for software that filters input across applications. KeyboardLock uses this permission only to create and manage its keyboard event tap.

Accessibility is a powerful system permission. The implementation is intentionally small and open source so its behavior can be audited. The app does not use the Accessibility API to inspect windows, read interface text, control other apps, or observe user activity.

You can revoke access at any time under **System Settings → Privacy & Security → Accessibility**. KeyboardLock cannot block keyboard events after access is revoked.

## Stored data

KeyboardLock stores one local `UserDefaults` value:

| Key | Value | Purpose |
|---|---|---|
| `lockDurationSeconds` | `60`, `180`, or `300` | Remembers the selected automatic unlock duration |

No account, device identifier, usage history, or biometric result is stored. Removing the app and its preferences removes this setting.

The bundled `PrivacyInfo.xcprivacy` declares no tracking or collected data. It lists `UserDefaults` under Apple's required-reason API category with reason `CA92.1`: reading and writing information that is accessible only to this app.

## Network access and third parties

The app has no network client, server endpoint, analytics SDK, advertising SDK, or third-party runtime dependency. It does not share data with the maintainer or any third party.

Installing or building the project may involve services you choose to use, such as GitHub, Homebrew, Xcode, and Apple's developer services. Their privacy practices are separate from KeyboardLock.

## Scope and limitations

KeyboardLock is a keyboard-cleaning convenience utility. It is not an authentication system, parental-control product, endpoint-security tool, or replacement for locking your Mac.

The power/Touch ID button is intentionally not blocked. Hardware behavior, other privileged software, and macOS itself remain outside the app's control.

## Verifying these claims

The relevant implementation is concentrated in:

- `KeyboardLock/Core/KeyboardBlocker.swift`
- `KeyboardLock/Core/KeyboardEventFilterPolicy.swift`
- `KeyboardLock/App/AppState.swift`
- `KeyboardLock/Resources/PrivacyInfo.xcprivacy`

Changes that add data collection, networking, logging of input events, or a third-party runtime service must be called out explicitly in a pull request and reflected in this document before merge.

## Questions

For privacy questions, open a GitHub issue without including sensitive information. For a private security concern, follow [SECURITY.md](../SECURITY.md).
