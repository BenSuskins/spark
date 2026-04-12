import SwiftUI
import CoreLocation

struct AddStepSheet: View {
    let model: ItineraryModel
    let venueSearchService: VenueSearchService?

    @Environment(\.dismiss) private var dismiss
    @State private var venueName = ""
    @State private var venueCoordinate: CLLocationCoordinate2D?
    @State private var time = Date()
    @State private var notes = ""
    @State private var showingVenuePicker = false

    init(model: ItineraryModel, venueSearchService: VenueSearchService? = nil) {
        self.model = model
        self.venueSearchService = venueSearchService
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("Venue name", text: $venueName)

                        if venueSearchService != nil {
                            Button {
                                showingVenuePicker = true
                            } label: {
                                Image(systemName: "map")
                            }
                        }
                    }

                    if venueCoordinate != nil {
                        Label("Location selected", systemImage: "mappin.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                }

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
                                venueCoordinate: venueCoordinate,
                                time: time,
                                notes: notes
                            )
                            dismiss()
                        }
                    }
                    .disabled(venueName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $showingVenuePicker) {
                if let venueSearchService {
                    VenuePicker(venueSearchService: venueSearchService) { venue in
                        venueName = venue.name
                        venueCoordinate = venue.coordinate
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
