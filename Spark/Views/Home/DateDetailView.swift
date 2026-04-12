import SwiftUI
import MapKit

struct DateDetailView: View {
    @State var model: ItineraryModel
    var venueSearchService: VenueSearchService?
    var repository: DateRepository?
    @State private var showingAddStep = false
    @State private var showingJournal = false

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

            if model.plannedDate.status == .completed || model.plannedDate.date < .now {
                Section {
                    if let repository {
                        NavigationLink {
                            JournalEntryView(model: JournalModel(
                                repository: repository,
                                plannedDate: model.plannedDate
                            ))
                        } label: {
                            Label("Journal Entry", systemImage: "book")
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
