import SwiftUI

struct MenuBarView: View {
    @ObservedObject var state: AppState

    var body: some View {
        if state.isLocked {
            Text("Keyboard locked · \(formattedTime)")
            Button(state.isAuthenticating ? "Waiting for Touch ID…" : "Unlock with Touch ID…") {
                state.unlockWithTouchID()
            }
            .disabled(!state.isTouchIDAvailable || state.isAuthenticating)
        } else {
            Button("Lock keyboard") {
                state.lock()
            }

            Picker("Safety timer", selection: $state.lockDuration) {
                Text("1 minute").tag(60)
                Text("3 minutes").tag(180)
                Text("5 minutes").tag(300)
            }

            if !state.isAccessibilityTrusted {
                Divider()
                Button("Grant Accessibility access…") {
                    state.requestAccessibilityAccess()
                    state.openAccessibilitySettings()
                }
            }
        }

        if let statusMessage = state.statusMessage {
            Divider()
            Text(statusMessage)
        }

        Divider()
        Button("Quit KeyboardLock") {
            state.quit()
        }
        .onAppear {
            state.refreshAccessibilityStatus()
            state.refreshTouchIDAvailability()
        }
    }

    private var formattedTime: String {
        let minutes = state.remainingSeconds / 60
        let seconds = state.remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
