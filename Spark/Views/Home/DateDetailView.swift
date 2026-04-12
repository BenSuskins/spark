import SwiftUI
import MapKit

struct DateDetailView: View {
    @State var model: ItineraryModel
    var venueSearchService: VenueSearchService?
    @State private var showingAddStep = false

    var body: some View {
        List {
            if !model.steps.isEmpty {
                Section("Map") {
                    ItineraryMapView(steps: model.steps)
                        .frame(height: 250)
                        .listRowInsets(EdgeInsets())
                }
            }

            Section("Itinerary") {
                if model.steps.isEmpty {
                    ContentUnavailableView(
                        "No Steps Yet",
                        systemImage: "list.number",
                        description: Text("Tap + to add your first stop")
                    )
                } else {
                    ForEach(model.steps) { step in
                        ItineraryStepRow(step: step)
                    }
                    .onDelete { indexSet in
                        Task {
                            for index in indexSet {
                                await model.deleteStep(model.steps[index])
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(model.plannedDate.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddStep = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddStep) {
            AddStepSheet(model: model, venueSearchService: venueSearchService)
        }
        .task {
            await model.loadSteps()
        }
    }
}
