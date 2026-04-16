import SwiftUI

struct HomeTab: View {
    var model: HomeModel
    let repository: DateRepository
    let venueSearchService: VenueSearchService
    let groupIdentifiers: [String]
    var groupPickerMenu: GroupPickerMenu?
    @State private var dateToDelete: PlannedDate?

    var body: some View {
        NavigationStack {
            List {
                Section("Upcoming") {
                    if model.upcomingDates.isEmpty {
                        ContentUnavailableView(
                            "No Upcoming Dates",
                            systemImage: "calendar",
                            description: Text("Plan a date from your ideas list")
                        )
                    } else {
                        ForEach(model.upcomingDates) { plannedDate in
                            NavigationLink(value: plannedDate) {
                                DateCard(plannedDate: plannedDate)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    dateToDelete = plannedDate
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }

                Section("Recent") {
                    if model.pastDates.isEmpty {
                        ContentUnavailableView(
                            "No Past Dates",
                            systemImage: "clock",
                            description: Text("Your date history will appear here")
                        )
                    } else {
                        ForEach(model.pastDates) { plannedDate in
                            NavigationLink(value: plannedDate) {
                                DateCard(plannedDate: plannedDate)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    dateToDelete = plannedDate
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Home")
            .toolbar {
                if let groupPickerMenu {
                    ToolbarItem(placement: .topBarLeading) {
                        groupPickerMenu
                    }
                }
            }
            .navigationDestination(for: PlannedDate.self) { plannedDate in
                DateDetailView(
                    model: ItineraryModel(repository: repository, plannedDate: plannedDate),
                    venueSearchService: venueSearchService,
                    repository: repository
                )
            }
            .confirmationDialog("Delete Date", isPresented: Binding(
                get: { dateToDelete != nil },
                set: { if !$0 { dateToDelete = nil } }
            ), titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let plannedDate = dateToDelete {
                        Task { await model.deletePlannedDate(plannedDate) }
                    }
                }
            } message: {
                Text("This date and its itinerary will be permanently deleted.")
            }
            .task {
                await model.loadDates(for: groupIdentifiers)
            }
        }
    }
}

#Preview {
    let repository = FakeDateRepository()
    HomeTab(
        model: HomeModel(repository: repository, currentUserIdentifier: "preview-user"),
        repository: repository,
        venueSearchService: FakeVenueSearchService(),
        groupIdentifiers: ["preview-group"]
    )
}
