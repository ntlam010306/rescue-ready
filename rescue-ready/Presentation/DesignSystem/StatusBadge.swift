import SwiftUI

/// Shows a batch status with an icon and text, never colour alone.
struct StatusBadge: View {
    let status: BatchStatus

    var body: some View {
        Label(status.displayName, systemImage: symbolName)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(tint)
            .background(tint.opacity(0.15), in: Capsule())
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Status: \(status.displayName)")
    }

    private var symbolName: String {
        switch status {
        case .awaitingCheck: return "clock"
        case .cleared: return "checkmark.seal"
        case .failedCheck: return "xmark.octagon"
        case .handedOver: return "shippingbox"
        case .discarded: return "trash"
        }
    }

    private var tint: Color {
        switch status {
        case .awaitingCheck: return .orange
        case .cleared: return .green
        case .failedCheck: return .red
        case .handedOver: return .blue
        case .discarded: return .secondary
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        ForEach(BatchStatus.allCases, id: \.self) { StatusBadge(status: $0) }
    }
    .padding()
}
