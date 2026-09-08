import AppKit
import SwiftUI

@main
struct KeyboardLockApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(state: state)
        } label: {
            Label(
                state.isLocked ? "Keyboard locked" : "KeyboardLock",
                systemImage: state.isLocked ? "lock.fill" : "keyboard"
            )
        }
        .menuBarExtraStyle(.menu)
    }
}
