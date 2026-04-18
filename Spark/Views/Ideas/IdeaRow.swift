import SwiftUI

/// A single idea card. Category-themed emoji chip on the left, title in the
/// middle, score pill + up/down voting on the right. The "down" vote is a
/// gentle `moon.zzz` ("not tonight") — never a red thumbs-down.
struct IdeaRow: View {
    let idea: Idea
    let score: Int
    let currentUserVote: Int?
    let onUpvote: () -> Void
    let onDownvote: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text(idea.category.emoji)
                .font(.system(size: 24))
                .frame(width: 44, height: 44)
                .background(SparkColors.accentMuted)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(idea.title)
                    .font(.headline)
                    .foregroundStyle(SparkColors.textPrimary)
                    .lineLimit(2)
                Text(idea.category.rawValue)
                    .font(.caption)
                    .foregroundStyle(SparkColors.textSecondary)
            }

            Spacer()

            HStack(spacing: 8) {
                VoteButton(
                    icon: currentUserVote == -1 ? "moon.zzz.fill" : "moon.zzz",
                    isActive: currentUserVote == -1,
                    tint: SparkColors.soft,
                    action: onDownvote
                )

                SparkScorePill(score: score)

                VoteButton(
                    icon: currentUserVote == 1 ? "heart.fill" : "heart",
                    isActive: currentUserVote == 1,
                    tint: SparkColors.accent,
                    action: onUpvote
                )
            }
        }
        .padding(14)
        .sparkCard(cornerRadius: 20)
    }
}

private struct VoteButton: View {
    let icon: String
    let isActive: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            withAnimation(SparkSprings.standard) { action() }
        }) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isActive ? tint : SparkColors.textSecondary)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 36, height: 36)
                .background(isActive ? tint.opacity(0.12) : SparkColors.surfaceElevated)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
