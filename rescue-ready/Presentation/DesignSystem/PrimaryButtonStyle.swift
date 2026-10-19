import SwiftUI

/// Full-width, high-emphasis button for the main action on a screen.
/// At least 50 pt tall, above the 44 pt minimum touch target.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 50)
            .padding(.horizontal)
            .foregroundStyle(.white)
            .background(background(isPressed: configuration.isPressed),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func background(isPressed: Bool) -> Color {
        guard isEnabled else { return Color.accentColor.opacity(0.4) }
        return isPressed ? Color.accentColor.opacity(0.8) : Color.accentColor
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}
