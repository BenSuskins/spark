import SwiftUI

struct AddStepSheet: View {
    let model: ItineraryModel

    @Environment(\.dismiss) private var dismiss
    @State private var venueName = ""
    @State private var time = Date()
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Venue name", text: $venueName)

                DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)

                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(3)
            }
            .navigationTitle("Add Stop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await model.addStep(
                                venueName: venueName,
                                venueCoordinate: nil,
                                time: time,
                                notes: notes
                            )
                            dismiss()
                        }
                    }
                    .disabled(venueName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
