import SwiftUI

struct ItineraryStepRow: View {
    let step: ItineraryStep

    var body: some View {
        HStack(alignment: .top) {
            Text("\(step.order)")
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(step.venueName)
                    .font(.body)

                Text(step.time, style: .time)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !step.notes.isEmpty {
                    Text(step.notes)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
