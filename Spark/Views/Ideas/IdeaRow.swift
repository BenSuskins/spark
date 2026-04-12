import SwiftUI

struct IdeaRow: View {
    let idea: Idea
    let score: Int
    let currentUserVote: Int?
    let onUpvote: () -> Void
    let onDownvote: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(idea.title)
                    .font(.body)
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: onDownvote) {
                    Image(systemName: currentUserVote == -1 ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                        .foregroundStyle(currentUserVote == -1 ? .red : .secondary)
                }
                .buttonStyle(.plain)

                Text("\(score)")
                    .font(.headline)
                    .monospacedDigit()
                    .frame(minWidth: 24)

                Button(action: onUpvote) {
                    Image(systemName: currentUserVote == 1 ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .foregroundStyle(currentUserVote == 1 ? .green : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}
