import SwiftUI

struct DateCard: View {
    let plannedDate: PlannedDate

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(plannedDate.title)
                .font(.headline)

            HStack {
                Image(systemName: plannedDate.status == .planned ? "calendar" : "checkmark.circle")
                    .foregroundStyle(plannedDate.status == .planned ? .blue : .green)

                Text(plannedDate.date, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(plannedDate.date, style: .time)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
