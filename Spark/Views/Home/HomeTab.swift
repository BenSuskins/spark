import SwiftUI

struct HomeTab: View {
    var model: HomeModel
    let repository: DateRepository
    let venueSearchService: VenueSearchService
    let groupIdentifier: String

    @State private var dateToDelete: PlannedDate?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    heroSection
                    upcomingSection
                    recentSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(SparkColors.background)
            .navigationTitle("Home")
            .navigationDestination(for: PlannedDate.self) { plannedDate in
                DateDetailView(
                    model: ItineraryModel(repository: repository, plannedDate: plannedDate),
                    venueSearchService: venueSearchService,
                    repository: repository
                )
            }
            .confirmationDialog(
                "Delete date?",
                isPresented: Binding(
                    get: { dateToDelete != nil },
                    set: { if !$0 { dateToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let plannedDate = dateToDelete {
                        Task { await model.deletePlannedDate(plannedDate) }
                    }
                }
            } message: {
                Text("This date and its itinerary will be permanently deleted.")
            }
            .task(id: groupIdentifier) {
                await model.loadDates(for: groupIdentifier)
            }
            .refreshable {
                await model.loadDates(for: groupIdentifier)
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var heroSection: some View {
        if let next = model.upcomingDates.first {
            NavigationLink(value: next) {
                DateCard(plannedDate: next, style: .hero)
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button(role: .destructive) { dateToDelete = next } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        } else {
            EmptyHero()
        }
    }

    @ViewBuilder
    private var upcomingSection: some View {
        let others = Array(model.upcomingDates.dropFirst())
        if !others.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Also coming up")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(others) { plannedDate in
                            NavigationLink(value: plannedDate) {
                                DateCard(plannedDate: plannedDate, style: .compact)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) { dateToDelete = plannedDate } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
    }

    @ViewBuilder
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recent")

            if model.pastDates.isEmpty {
                EmptyRecent()
            } else {
                VStack(spacing: 10) {
                    ForEach(model.pastDates) { plannedDate in
                        NavigationLink(value: plannedDate) {
                            DateCard(plannedDate: plannedDate, style: .row)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) { dateToDelete = plannedDate } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Supporting views

private struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title3.weight(.semibold))
            .foregroundStyle(SparkColors.textPrimary)
            .padding(.horizontal, 4)
    }
}

private struct EmptyHero: View {
    var body: some View {
        VStack(spacing: 14) {
            Text("✨")
                .font(.system(size: 56))
            Text("No date on the horizon")
                .font(.title3.weight(.semibold))
                .foregroundStyle(SparkColors.textPrimary)
            Text("Head to Ideas and promote one to a date.")
                .font(.subheadline)
                .foregroundStyle(SparkColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(SparkColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

private struct EmptyRecent: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.title3)
                .foregroundStyle(SparkColors.textSecondary)
            Text("Your date history will appear here.")
                .font(.subheadline)
                .foregroundStyle(SparkColors.textSecondary)
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sparkCard(cornerRadius: 20)
    }
}
