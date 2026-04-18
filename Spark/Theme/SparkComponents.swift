import SwiftUI

// MARK: - Buttons

/// Primary CTA: filled capsule in the warm accent.
struct SparkPrimaryButtonStyle: ButtonStyle {
    var color: Color = SparkColors.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(configuration.isPressed ? color.opacity(0.85) : color)
            .clipShape(Capsule())
    }
}

/// Secondary CTA: surface-filled capsule with primary-text label.
struct SparkSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(SparkColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(configuration.isPressed ? SparkColors.surfaceElevated : SparkColors.surface)
            .clipShape(Capsule())
    }
}

/// Soft-decline button ("not tonight"). Never red.
struct SparkSoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(SparkColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(SparkColors.surface)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// Text-only tertiary action in accent.
struct SparkGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(SparkColors.accent)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

// MARK: - Containers

/// Standard Spark card container. Continuous rounded rectangle on `surface`.
struct SparkCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(SparkColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

extension View {
    func sparkCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(SparkCardModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Large form field

/// A large rounded input container used on AddStep, AddIdea, Journal, Create group.
struct SparkFormField<Content: View>: View {
    let title: String?
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SparkColors.textSecondary)
                    .textCase(.uppercase)
                    .padding(.horizontal, 4)
            }
            content()
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SparkColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}

// MARK: - Score pill

/// The score pill used on IdeaRow. Styling is identical for positive/negative;
/// we never turn negative scores red — the neutrality is the point.
struct SparkScorePill: View {
    let score: Int

    var body: some View {
        Text("\(score)")
            .font(.subheadline.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(score > 0 ? SparkColors.accent : SparkColors.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(score > 0 ? SparkColors.accentMuted : SparkColors.surface)
            .clipShape(Capsule())
    }
}

// MARK: - Avatar stack

/// Renders up to `limit` emoji/initials as a tight overlapping stack. Anything
/// beyond becomes a trailing `+N` chip.
struct SparkAvatarStack: View {
    let labels: [String]
    var limit: Int = 3
    var size: CGFloat = 24

    var body: some View {
        let visible = Array(labels.prefix(limit))
        let overflow = max(0, labels.count - limit)

        HStack(spacing: -size * 0.35) {
            ForEach(Array(visible.enumerated()), id: \.offset) { _, label in
                AvatarBubble(label: label, size: size)
            }
            if overflow > 0 {
                Text("+\(overflow)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SparkColors.textSecondary)
                    .frame(width: size, height: size)
                    .background(SparkColors.surface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(SparkColors.background, lineWidth: 1.5))
            }
        }
    }
}

private struct AvatarBubble: View {
    let label: String
    let size: CGFloat

    var body: some View {
        Text(label)
            .font(.system(size: size * 0.55))
            .frame(width: size, height: size)
            .background(SparkColors.accentMuted)
            .foregroundStyle(SparkColors.accent)
            .clipShape(Circle())
            .overlay(Circle().stroke(SparkColors.background, lineWidth: 1.5))
    }
}

// MARK: - Springs

enum SparkSprings {
    static let standard: Animation = .spring(response: 0.35, dampingFraction: 0.82)
    static let sheet: Animation = .spring(response: 0.45, dampingFraction: 0.78)
    static let celebratory: Animation = .spring(response: 0.55, dampingFraction: 0.6)
}
