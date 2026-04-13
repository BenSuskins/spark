import Foundation
import Observation

@MainActor
@Observable
final class HomeModel {
    private(set) var upcomingDates: [PlannedDate] = []
    private(set) var pastDates: [PlannedDate] = []
    private(set) var isLoading = false
    private(set) var error: SparkError?

    var selectedGroupIdentifier: String?

    private let repository: DateRepository
    let currentUserIdentifier: String

    init(repository: DateRepository, currentUserIdentifier: String) {
        self.repository = repository
        self.currentUserIdentifier = currentUserIdentifier
    }

    func loadDates(for groupIdentifiers: [String]) async {
        isLoading = true
        error = nil

        let targetGroups: [String]
        if let selected = selectedGroupIdentifier {
            targetGroups = [selected]
        } else {
            targetGroups = groupIdentifiers
        }

        var allUpcoming: [PlannedDate] = []
        var allPast: [PlannedDate] = []

        for groupIdentifier in targetGroups {
            let upcomingResult = await repository.fetchUpcomingDates(for: groupIdentifier)
            if case .success(let dates) = upcomingResult {
                allUpcoming.append(contentsOf: dates)
            }

            let pastResult = await repository.fetchPastDates(for: groupIdentifier)
            if case .success(let dates) = pastResult {
                allPast.append(contentsOf: dates)
            }
        }

        upcomingDates = allUpcoming.sorted { $0.date < $1.date }
        pastDates = allPast.sorted { $0.date > $1.date }
        isLoading = false
    }

    func promoteIdeaToDate(_ idea: Idea, date: Date) async -> Result<PlannedDate, SparkError> {
        let plannedDate = PlannedDate(
            id: UUID().uuidString,
            title: idea.title,
            date: date,
            status: .planned,
            groupIdentifier: idea.groupIdentifier
        )

        let result = await repository.createPlannedDate(plannedDate, in: idea.groupIdentifier)
        if case .success = result {
            var markedIdea = idea
            markedIdea.isPlanned = true
            _ = await repository.updateIdea(markedIdea)
        }
        return result
    }

    func deletePlannedDate(_ plannedDate: PlannedDate) async {
        let result = await repository.deletePlannedDate(plannedDate)
        if case .failure(let sparkError) = result {
            error = sparkError
            return
        }
        upcomingDates.removeAll { $0.id == plannedDate.id }
        pastDates.removeAll { $0.id == plannedDate.id }
    }
}
