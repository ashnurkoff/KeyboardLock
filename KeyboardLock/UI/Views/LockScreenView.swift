import SwiftUI

struct LockScreenView: View {
    @ObservedObject var state: AppState
    @State private var isHolding = false

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "keyboard")
                .font(.system(size: 44, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.blue)

            VStack(spacing: 7) {
                Text("Keyboard locked")
                    .font(.title2.weight(.semibold))
                Text("Safe to clean · unlocks automatically in \(formattedTime)")
                    .foregroundStyle(.secondary)
            }

            Button(action: state.unlockWithTouchID) {
                Label(
                    state.isAuthenticating ? "Waiting for Touch ID…" : "Unlock with Touch ID",
                    systemImage: "touchid"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!state.isTouchIDAvailable || state.isAuthenticating)

            if let statusMessage = state.statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            Text(isHolding ? "Keep holding…" : "Hold for \(UnlockPolicy.holdDurationSeconds) seconds to unlock")
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(isHolding ? Color.green.opacity(0.9) : Color.secondary.opacity(0.16))
                .foregroundStyle(isHolding ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .scaleEffect(isHolding ? 0.98 : 1)
                .animation(.easeOut(duration: 0.15), value: isHolding)
                .onLongPressGesture(
                    minimumDuration: UnlockPolicy.holdDuration,
                    maximumDistance: 40,
                    pressing: { isHolding = $0 },
                    perform: state.unlock
                )
        }
        .padding(30)
        .frame(width: 460, height: 390)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var formattedTime: String {
        let minutes = state.remainingSeconds / 60
        let seconds = state.remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
