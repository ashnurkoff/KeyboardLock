import AppKit
import SwiftUI

@MainActor
final class LockPanelController {
    private let panel: NSPanel

    init(state: AppState) {
        let rootView = LockScreenView(state: state)
        let hostingView = NSHostingView(rootView: rootView)

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 390),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.styleMask.remove(.closable)
        panel.styleMask.remove(.miniaturizable)
        panel.styleMask.remove(.resizable)
        panel.isMovable = false
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.contentView = hostingView
    }

    func show() {
        positionOnActiveScreen()
        NSApplication.shared.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel.orderOut(nil)
    }

    private func positionOnActiveScreen() {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) })
            ?? NSScreen.main
            ?? NSScreen.screens.first

        guard let visibleFrame = screen?.visibleFrame else { return }
        let origin = NSPoint(
            x: visibleFrame.midX - panel.frame.width / 2,
            y: visibleFrame.midY - panel.frame.height / 2
        )
        panel.setFrameOrigin(origin)
    }
}
