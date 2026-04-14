import SwiftUI

struct SparkPrimaryButtonStyle: ButtonStyle {
    var color: Color = SparkColors.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(configuration.isPressed ? color.opacity(0.8) : color)
            .clipShape(Capsule())
    }
}

struct SparkSecondaryButtonStyle: ButtonStyle {
    var color: Color = SparkColors.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .stroke(color, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct SparkCardModifier: ViewModifier {
    var elevated: Bool = false

    func body(content: Content) -> some View {
        content
            .background(SparkColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(
                color: elevated ? .black.opacity(0.12) : .clear,
                radius: elevated ? 15 : 0,
                x: 0,
                y: elevated ? 3 : 0
            )
    }
}

extension View {
    func sparkCard(elevated: Bool = false) -> some View {
        modifier(SparkCardModifier(elevated: elevated))
    }
}
