import SwiftUI
import MapKit

/// Timeline-first detail view for a `PlannedDate`. A map summary tile sits at
/// the top; the itinerary renders as a vertical timeline with connector
/// segments; journal entry is offered once the date has happened. A floating
/// "Add stop" pill is the primary affordance.
struct DateDetailView: View {
    @State var model: ItineraryModel
    var venueSearchService: VenueSearchService?
    var repository: DateRepository?

    @State private var showingAddStep = false
    @State private var expandedMap = false

    private var hasCoordinates: Bool {
        model.steps.contains { $0.venueCoordinate != nil }
    }

    private var hasOccurred: Bool {
        model.plannedDate.status == .completed || model.plannedDate.date < .now
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    if hasCoordinates {
                        mapTile
                    }

                    timelineSection

                    if hasOccurred, let repository {
                        journalEntryCard(repository: repository)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
            .background(SparkColors.background)

            floatingAddButton
        }
        .navigationTitle(model.plannedDate.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddStep) {
            AddStepSheet(model: model, venueSearchService: venueSearchService)
        }
        .sheet(isPresented: $expandedMap) {
            NavigationStack {
                ItineraryMapView(steps: model.steps)
                    .ignoresSafeArea(edges: .bottom)
                    .navigationTitle("Route")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { expandedMap = false }
                        }
                    }
            }
        }
        .task {
            await model.loadSteps()
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(model.plannedDate.date.formatted(date: .complete, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(SparkColors.textSecondary)
            Text(model.plannedDate.title)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(SparkColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var mapTile: some View {
        Button {
            expandedMap = true
        } label: {
            ItineraryMapView(steps: model.steps)
                .aspectRatio(16.0 / 9.0, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .allowsHitTesting(false)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(SparkColors.textPrimary)
                        .padding(8)
                        .background(.thinMaterial, in: Circle())
                        .padding(12)
                }
        }
        .buttonStyle(.plain)
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Itinerary")
                .font(.title3.weight(.semibold))
                .foregroundStyle(SparkColors.textPrimary)

            if model.steps.isEmpty {
                EmptyItinerary()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(model.steps.enumerated()), id: \.element.id) { index, step in
                        ItineraryStepRow(
                            step: step,
                            isFirst: index == 0,
                            isLast: index == model.steps.count - 1
                        )
                        .contextMenu {
                            Button(role: .destructive) {
                                Task { await model.deleteStep(step) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }

    private func journalEntryCard(repository: DateRepository) -> some View {
        NavigationLink {
            JournalEntryView(model: JournalModel(
                repository: repository,
                plannedDate: model.plannedDate
            ))
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(SparkColors.accentMuted)
                        .frame(width: 44, height: 44)
                    Image(systemName: "book.pages")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(SparkColors.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Journal")
                        .font(.headline)
                        .foregroundStyle(SparkColors.textPrimary)
                    Text("Capture the moment while it's fresh.")
                        .font(.caption)
                        .foregroundStyle(SparkColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(SparkColors.textTertiary)
            }
            .padding(16)
            .sparkCard(cornerRadius: 20)
        }
        .buttonStyle(.plain)
    }

    private var floatingAddButton: some View {
        Button {
            showingAddStep = true
        } label: {
            Label("Add stop", systemImage: "plus")
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(SparkColors.accent, in: Capsule())
                .shadow(color: SparkColors.accent.opacity(0.35), radius: 14, y: 6)
        }
        .padding(.trailing, 16)
        .padding(.bottom, 20)
    }
}

private struct EmptyItinerary: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "list.number")
                .font(.title2)
                .foregroundStyle(SparkColors.textSecondary)
            Text("No stops yet")
                .font(.headline)
                .foregroundStyle(SparkColors.textPrimary)
            Text("Tap Add stop to build the itinerary.")
                .font(.subheadline)
                .foregroundStyle(SparkColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .sparkCard(cornerRadius: 20)
    }
}
