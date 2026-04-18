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
    @State private var showingError = false

    init(model: ItineraryModel, venueSearchService: VenueSearchService? = nil) {
        self.model = model
        self.venueSearchService = venueSearchService
    }

    private var canSave: Bool {
        !venueName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    SparkFormField(title: "Venue") {
                        HStack(spacing: 12) {
                            TextField("Where are you headed?", text: $venueName)
                                .textInputAutocapitalization(.words)
                                .font(.body)

                            if venueSearchService != nil {
                                Button {
                                    showingVenuePicker = true
                                } label: {
                                    Image(systemName: "map")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(SparkColors.accent)
                                        .frame(width: 36, height: 36)
                                        .background(SparkColors.accentMuted)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if venueCoordinate != nil {
                        Label("Location pinned", systemImage: "mappin.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SparkColors.success)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }

                    SparkFormField(title: "Time") {
                        DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    SparkFormField(title: "Notes") {
                        TextField("Anything to remember?", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .font(.body)
                    }
                }
                .padding(16)
            }
            .background(SparkColors.background)
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
                            if model.error == nil {
                                dismiss()
                            } else {
                                showingError = true
                            }
                        }
                    }
                    .disabled(!canSave)
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
        .presentationDetents([.medium, .large])
        .alert("Failed to Add Stop", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(model.error?.localizedDescription ?? "An unknown error occurred.")
        }
    }
}
