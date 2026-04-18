import SwiftUI

/// Single row in the date detail timeline. A vertical connector runs down the
/// left edge with a filled accent dot at the row's time; the right side shows
/// time, venue, and optional notes on a card.
struct ItineraryStepRow: View {
    let step: ItineraryStep
    var isFirst: Bool = false
    var isLast: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            TimelineConnector(isFirst: isFirst, isLast: isLast)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 6) {
                Text(step.time, style: .time)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SparkColors.accent)

                Text(step.venueName)
                    .font(.headline)
                    .foregroundStyle(SparkColors.textPrimary)

                if !step.notes.isEmpty {
                    Text(step.notes)
                        .font(.subheadline)
                        .foregroundStyle(SparkColors.textSecondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .sparkCard(cornerRadius: 18)
            .padding(.bottom, isLast ? 0 : 10)
        }
    }
}

private struct TimelineConnector: View {
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                if !isFirst {
                    Rectangle()
                        .fill(SparkColors.accentMuted)
                        .frame(width: 2)
                        .frame(maxHeight: 20)
                        .frame(width: proxy.size.width, alignment: .center)
                }

                if !isLast {
                    Rectangle()
                        .fill(SparkColors.accentMuted)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .offset(y: 20)
                        .frame(width: proxy.size.width, alignment: .center)
                }

                Circle()
                    .fill(SparkColors.accent)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .stroke(SparkColors.background, lineWidth: 3)
                    )
                    .offset(y: 14)
                    .frame(width: proxy.size.width, alignment: .center)
            }
        }
    }
}
