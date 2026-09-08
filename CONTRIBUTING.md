# Contributing to KeyboardLock

Thank you for helping make keyboard cleaning safer and less annoying. Contributions of code, tests, documentation, design, and reproducible bug reports are welcome.

## Before you start

- Search existing issues and pull requests.
- Open an issue before a large behavioral or architectural change.
- Read [Architecture](docs/ARCHITECTURE.md), [Building](docs/BUILDING.md), and [Privacy](docs/PRIVACY.md).
- Never include passwords, typed text, fingerprints, signing credentials, or other sensitive data in an issue, test fixture, screenshot, or log.

## Development setup

```bash
git clone https://github.com/ashnurkoff/KeyboardLock.git
cd KeyboardLock
brew install xcodegen
make check
```

See [docs/BUILDING.md](docs/BUILDING.md) for signing, Accessibility setup, and manual testing.

## Repository conventions

- `project.yml` is the source of truth for the generated Xcode project.
- `KeyboardLock.xcodeproj` is checked in so the project can be opened immediately. Run `make generate` after changing project settings and commit both files.
- Keep app lifecycle and coordination in `KeyboardLock/App/`.
- Keep input decisions and non-UI policy in `KeyboardLock/Core/`.
- Keep SwiftUI and AppKit presentation code in `KeyboardLock/UI/`.
- Keep app metadata and assets in `KeyboardLock/Resources/`.
- Put deterministic XCTest coverage in `KeyboardLockTests/`.
- Use four spaces in Swift and two spaces in YAML.
- Prefer small, focused types and avoid work in the event-tap callback.

## Safety invariants

Every change must preserve these guarantees:

1. Mouse and trackpad events are never blocked.
2. An automatic timeout always restores keyboard input.
3. A mouse-only fallback remains available when Touch ID cannot be used.
4. Cancelling or failing Touch ID does not silently unlock the keyboard.
5. Quitting disables the event tap before the process terminates.
6. The power/Touch ID button is not presented as blocked.

Do not add a new blocked event type without a focused test and physical-device verification.

## Privacy invariants

KeyboardLock must not:

- record character content or key codes;
- log or persist keyboard events;
- collect fingerprint or biometric data;
- add analytics, advertising, telemetry, or tracking;
- transmit user or event data;
- add a third-party runtime service without prior public discussion.

Any intentional change to data handling requires an issue, explicit PR disclosure, and an update to `docs/PRIVACY.md`.

## Making a change

1. Fork the repository and create a focused branch, such as `fix/media-key-filter`.
2. Make the smallest coherent change.
3. Add or update tests for deterministic behavior.
4. Run `make check`.
5. Complete the manual safety checklist for input or unlock changes.
6. Update documentation when behavior, permissions, privacy, setup, or release steps change.
7. Open a pull request using the template.

## Commit messages

Use short, imperative Conventional Commit-style messages:

```text
feat: add a timer option
fix: preserve auxiliary mouse events
test: cover media-key filtering
docs: clarify Accessibility setup
```

Common prefixes are `feat`, `fix`, `test`, `docs`, `refactor`, `build`, and `chore`.

## Pull-request checklist

A reviewable pull request should:

- explain the user-visible problem and result;
- stay focused on one concern;
- include tests or explain why automated testing is impossible;
- pass CI and `make check` locally;
- include manual results for Accessibility, Touch ID, or input-filter changes;
- preserve privacy and safety invariants;
- contain no personal signing team, certificate, secret, or generated build output.

Maintainers may request smaller commits, additional tests, or a revised safety design before merge.

## Reporting bugs

Use the structured bug-report form. Include:

- macOS version;
- Mac model and architecture;
- built-in or external keyboard model;
- KeyboardLock version or commit;
- exact reproduction steps;
- Accessibility and Touch ID availability.

Describe which key category failed; do not paste what you typed while testing.

## Security reports

Do not open public issues for vulnerabilities. Follow [SECURITY.md](SECURITY.md) instead.

## License

By contributing, you agree that your contribution is licensed under the repository's [MIT License](LICENSE).
