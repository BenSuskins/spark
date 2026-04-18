import SwiftUI

/// Rich card for an upcoming or past `PlannedDate`. Two shapes:
/// - `.hero`: full-bleed card for the next upcoming date (large, gradient,
///   countdown, call to explore).
/// - `.compact`: fixed-width card for horizontal scroll rows.
/// - `.row`: wide row card for the Recent list below the hero.
struct DateCard: View {
    enum Style {
        case hero
        case compact
        case row
    }

    let plannedDate: PlannedDate
    var stepCount: Int = 0
    var participantLabels: [String] = []
    var style: Style = .row

    var body: some View {
        switch style {
        case .hero: HeroCard(plannedDate: plannedDate, stepCount: stepCount, participantLabels: participantLabels)
        case .compact: CompactCard(plannedDate: plannedDate, stepCount: stepCount)
        case .row: RowCard(plannedDate: plannedDate, stepCount: stepCount)
        }
    }
}

// MARK: - Hero

private struct HeroCard: View {
    let plannedDate: PlannedDate
    let stepCount: Int
    let participantLabels: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CountdownBadge(target: plannedDate.date)

            Text(plannedDate.title)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(2)

            Text(plannedDate.date.formatted(date: .complete, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))

            HStack(spacing: 12) {
                if stepCount > 0 {
                    HeroMetaChip(icon: "list.number", text: "\(stepCount) stop\(stepCount == 1 ? "" : "s")")
                }
                if !participantLabels.isEmpty {
                    SparkAvatarStack(labels: participantLabels, limit: 4, size: 26)
                }
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [SparkColors.accent, SparkColors.accent.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: SparkColors.accent.opacity(0.25), radius: 20, y: 10)
    }
}

private struct CountdownBadge: View {
    let target: Date

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.caption.weight(.semibold))
            Text(countdownText)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.white.opacity(0.22))
        .clipShape(Capsule())
    }

    private var countdownText: String {
        let interval = target.timeIntervalSinceNow
        if interval <= 0 { return "Today" }
        let days = Int(interval / 86400)
        if days >= 1 { return "In \(days) day\(days == 1 ? "" : "s")" }
        let hours = Int(interval / 3600)
        if hours >= 1 { return "In \(hours) hour\(hours == 1 ? "" : "s")" }
        let minutes = max(1, Int(interval / 60))
        return "In \(minutes) min"
    }
}

private struct HeroMetaChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.22))
        .clipShape(Capsule())
    }
}

// MARK: - Compact (horizontal scroll)

private struct CompactCard: View {
    let plannedDate: PlannedDate
    let stepCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [SparkColors.accentMuted, SparkColors.surfaceElevated],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 96)
                .overlay(
                    Image(systemName: "calendar")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(SparkColors.accent)
                )

            Text(plannedDate.title)
                .font(.headline)
                .foregroundStyle(SparkColors.textPrimary)
                .lineLimit(1)

            Text(plannedDate.date.formatted(.dateTime.weekday().month().day()))
                .font(.caption)
                .foregroundStyle(SparkColors.textSecondary)

            if stepCount > 0 {
                Label("\(stepCount) stop\(stepCount == 1 ? "" : "s")", systemImage: "list.number")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(SparkColors.textSecondary)
            }
        }
        .padding(14)
        .frame(width: 200, alignment: .leading)
        .sparkCard(cornerRadius: 20)
    }
}

// MARK: - Row (past dates)

private struct RowCard: View {
    let plannedDate: PlannedDate
    let stepCount: Int

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(SparkColors.accentMuted)
                    .frame(width: 44, height: 44)
                Image(systemName: plannedDate.status == .completed ? "checkmark" : "calendar")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(SparkColors.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(plannedDate.title)
                    .font(.headline)
                    .foregroundStyle(SparkColors.textPrimary)
                    .lineLimit(1)
                Text(plannedDate.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(SparkColors.textSecondary)
            }

            Spacer()

            if stepCount > 0 {
                Text("\(stepCount)")
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(SparkColors.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(SparkColors.surfaceElevated)
                    .clipShape(Capsule())
            }

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(SparkColors.textTertiary)
        }
        .padding(14)
        .sparkCard(cornerRadius: 20)
    }
}
