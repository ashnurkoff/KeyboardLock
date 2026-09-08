# Building and local development

## Prerequisites

- macOS 13 Ventura or newer
- Xcode 15 or newer
- Xcode command-line tools
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (verified with 2.46.0)
- Git

Install XcodeGen with Homebrew:

```bash
brew install xcodegen
```

Confirm the toolchain:

```bash
xcodebuild -version
xcodegen --version
swift --version
```

## Clone and generate the project

```bash
git clone https://github.com/ashnurkoff/KeyboardLock.git
cd KeyboardLock
make generate
open KeyboardLock.xcodeproj
```

`project.yml` is the source of truth for targets and build settings. Do not edit generated project settings without making the corresponding change in `project.yml`.

## Unsigned local build

An unsigned build is sufficient for compilation, tests, CI, and an initial local run:

```bash
make build
open build/Build/Products/Release/KeyboardLock.app
```

The Release build is universal and contains `arm64` and `x86_64` slices.

Because unsigned builds do not have a stable designated code-signing requirement, macOS may treat a rebuilt app as a new Accessibility client. Use a signed local build for repeated manual testing.

## Signed local build

You need an Apple Development signing identity from either a free or paid Apple developer account. Find your Team ID in Xcode under **Settings → Accounts**, then run:

```bash
DEVELOPMENT_TEAM=YOUR_TEAM_ID make signed-build
open build/Build/Products/Release/KeyboardLock.app
```

Or generate the project, open it in Xcode, and select your team under **KeyboardLock → Signing & Capabilities**.

The public project does not contain the maintainer's Team ID, certificates, provisioning data, or notarization credentials.

## Running tests

```bash
make test
```

The test target currently verifies:

- ordinary keyboard events are blocked;
- media/function and eject events are blocked;
- auxiliary mouse and unrelated system events pass through;
- common mouse and scroll events pass through;
- fallback unlocking requires a ten-second hold.

## Static analysis and full checks

```bash
make analyze
make check
```

`make check` generates the project, runs unit tests, creates an unsigned universal Release build, and runs Xcode's static analyzer.

## First-run Accessibility setup

1. Launch the exact app bundle you intend to test.
2. Open **System Settings → Privacy & Security → Accessibility** when prompted.
3. Enable KeyboardLock.
4. Quit and reopen KeyboardLock if macOS does not refresh trust immediately.

### Repeated permission prompt

Accessibility trust is sensitive to app identity, signature, and path. If the prompt keeps returning:

1. Quit KeyboardLock.
2. Remove every stale KeyboardLock entry from **Privacy & Security → Accessibility**.
3. Keep the current build at one stable path, such as `/Applications/KeyboardLock.app`.
4. Use the same Apple Development identity for future builds.
5. Add or enable that exact bundle and relaunch it.

Changing the bundle identifier, signing identity, executable contents, or location can cause macOS to evaluate the app again.

## Manual safety test

Run this checklist on a physical Mac before submitting an input-related change:

1. Set the timer to one minute.
2. Lock the keyboard and confirm letters, modifiers, shortcuts, and media keys do nothing.
3. Confirm pointer movement, clicks, scrolling, and the Touch ID button remain usable.
4. Cancel one Touch ID attempt and confirm the keyboard stays locked.
5. Authenticate successfully and confirm keyboard input returns immediately.
6. Lock again and verify the ten-second mouse hold restores input.
7. Lock once more and verify the timer restores input without interaction.
8. Quit while unlocked and confirm the app exits cleanly.

Do not begin a manual test without a reachable pointing device and a short safety timer.

## Project layout

```text
KeyboardLock/App/        App entry point and state coordination
KeyboardLock/Core/       Event filtering and unlock policy
KeyboardLock/UI/         AppKit panel and SwiftUI views
KeyboardLock/Resources/  Info.plist and asset catalog
KeyboardLockTests/       XCTest unit tests
docs/                    Architecture, privacy, build, and release docs
project.yml              XcodeGen project specification
Makefile                 Reproducible developer commands
```

## Common changes

### Change the event filter

Update `KeyboardEventFilterPolicy` first, add or adjust unit tests, and keep `KeyboardBlocker` focused on event-tap lifecycle. Never add mouse events to the blocked mask.

### Change an unlock path

Update `AppState`, the relevant SwiftUI view, automated tests where possible, and the manual safety checklist. Every release must keep at least one mouse-only recovery path plus the automatic timer.

### Change project settings

Edit `project.yml`, run `make generate`, and verify the generated `KeyboardLock.xcodeproj` diff. Never commit a personal development team or signing credential.

## Cleaning build output

```bash
make clean
```

Build directories are ignored by Git.
