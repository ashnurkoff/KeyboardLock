import AppKit
import ApplicationServices
import Foundation
@preconcurrency import LocalAuthentication

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var isLocked = false
    @Published private(set) var remainingSeconds = 0
    @Published private(set) var isAccessibilityTrusted = AXIsProcessTrusted()
    @Published private(set) var isTouchIDAvailable = false
    @Published private(set) var isAuthenticating = false
    @Published var statusMessage: String?
    @Published var lockDuration: Int {
        didSet {
            UserDefaults.standard.set(lockDuration, forKey: Self.durationDefaultsKey)
        }
    }

    private static let durationDefaultsKey = "lockDurationSeconds"

    private let keyboardBlocker = KeyboardBlocker()
    private var expirationDate: Date?
    private var countdownTimer: Timer?
    private var authenticationContext: LAContext?
    private lazy var lockPanel = LockPanelController(state: self)

    init() {
        let savedDuration = UserDefaults.standard.integer(forKey: Self.durationDefaultsKey)
        lockDuration = [60, 180, 300].contains(savedDuration) ? savedDuration : 180
        refreshTouchIDAvailability()

        if !isAccessibilityTrusted {
            requestAccessibilityAccess()
        }
    }

    func refreshAccessibilityStatus() {
        isAccessibilityTrusted = AXIsProcessTrusted()
    }

    func refreshTouchIDAvailability() {
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        isTouchIDAvailable = context.biometryType == .touchID
    }

    func requestAccessibilityAccess() {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: true] as CFDictionary
        isAccessibilityTrusted = AXIsProcessTrustedWithOptions(options)

        if !isAccessibilityTrusted {
            statusMessage = "Enable KeyboardLock in System Settings → Privacy & Security → Accessibility, then try again."
        }
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func lock() {
        refreshAccessibilityStatus()
        guard isAccessibilityTrusted else {
            requestAccessibilityAccess()
            return
        }

        do {
            try keyboardBlocker.start()
            isLocked = true
            statusMessage = nil
            expirationDate = Date().addingTimeInterval(TimeInterval(lockDuration))
            remainingSeconds = lockDuration
            startCountdown()
            lockPanel.show()
        } catch {
            statusMessage = error.localizedDescription
            keyboardBlocker.stop()
        }
    }

    func unlock() {
        guard isLocked else { return }

        authenticationContext?.invalidate()
        authenticationContext = nil
        isAuthenticating = false
        keyboardBlocker.stop()
        countdownTimer?.invalidate()
        countdownTimer = nil
        expirationDate = nil
        remainingSeconds = 0
        isLocked = false
        lockPanel.hide()
    }

    func unlockWithTouchID() {
        guard isLocked, !isAuthenticating else { return }

        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = ""

        var policyError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &policyError),
              context.biometryType == .touchID else {
            isTouchIDAvailable = context.biometryType == .touchID
            statusMessage = policyError?.localizedDescription ?? "Touch ID is unavailable on this Mac."
            return
        }

        isTouchIDAvailable = true
        isAuthenticating = true
        statusMessage = nil
        authenticationContext = context

        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Unlock the keyboard"
        ) { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self, self.authenticationContext === context else { return }

                self.authenticationContext = nil
                self.isAuthenticating = false

                if success {
                    self.unlock()
                } else {
                    self.handleAuthenticationError(error)
                }
            }
        }
    }

    func quit() {
        unlock()
        NSApplication.shared.terminate(nil)
    }

    private func startCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateCountdown()
            }
        }
        RunLoop.main.add(countdownTimer!, forMode: .common)
    }

    private func updateCountdown() {
        guard let expirationDate else { return }

        remainingSeconds = max(0, Int(ceil(expirationDate.timeIntervalSinceNow)))
        if remainingSeconds == 0 {
            unlock()
        }
    }

    private func handleAuthenticationError(_ error: Error?) {
        guard let error else { return }

        let code = LAError.Code(rawValue: (error as NSError).code)
        switch code {
        case .userCancel, .systemCancel, .appCancel:
            return
        default:
            statusMessage = error.localizedDescription
        }
    }
}
