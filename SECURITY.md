# Security policy

## Supported versions

Security fixes are applied to the current `main` branch and the latest published release.

| Version | Supported |
|---|---|
| `main` | Yes |
| Latest release, when available | Yes |
| Older releases | No |

## Reporting a vulnerability

Please use [GitHub private vulnerability reporting](https://github.com/ashnurkoff/KeyboardLock/security/advisories/new). Do not create a public issue for a suspected vulnerability.

Include:

- the affected version or commit;
- macOS version and hardware architecture;
- clear reproduction steps;
- the expected and observed security impact;
- a minimal proof of concept if it does not contain sensitive data.

Do not include passwords, typed text, fingerprint information, Apple credentials, certificates, private keys, or unrelated personal data.

You should receive an acknowledgement within seven days. The maintainer will validate the report, coordinate a fix and disclosure timeline, and credit the reporter unless anonymity is requested.

## Security scope

Relevant reports include:

- keyboard input remaining suppressed after every documented recovery path should have completed;
- mouse or trackpad input being blocked;
- keyboard events or biometric results being logged, stored, or transmitted;
- a bypass that unlocks without the required gesture, timer, or successful Touch ID result;
- unsafe code-signing, release, or update artifacts published by this repository.

## Product boundary

KeyboardLock is a cleaning utility, not a security control. It does not lock the user session, protect data from another person, replace the macOS lock screen, or block the power/Touch ID button at the hardware level. Reports whose only finding is that KeyboardLock does not provide those out-of-scope protections are not vulnerabilities.
