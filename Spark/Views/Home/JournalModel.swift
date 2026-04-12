import Foundation
import Observation

@MainActor
@Observable
final class JournalModel {
    private(set) var entry: JournalEntry?
    private(set) var isLoading = false
    private(set) var error: SparkError?

    var hasEntry: Bool { entry != nil }

    let plannedDate: PlannedDate
    private let repository: DateRepository

    init(repository: DateRepository, plannedDate: PlannedDate) {
        self.repository = repository
        self.plannedDate = plannedDate
    }

    func loadEntry() async {
        isLoading = true
        let result = await repository.fetchJournalEntry(for: plannedDate)

        if case .success(let loadedEntry) = result {
            entry = loadedEntry
        } else if case .failure(let sparkError) = result {
            error = sparkError
        }

        isLoading = false
    }

    func saveEntry(rating: Int, notes: String) async {
        let clampedRating = min(5, max(1, rating))

        if let existing = entry {
            let updated = JournalEntry(
                id: existing.id,
                plannedDateIdentifier: plannedDate.id,
                rating: clampedRating,
                notes: notes,
                createdDate: existing.createdDate
            )

            let result = await repository.updateJournalEntry(updated)
            if case .success(let updatedEntry) = result {
                entry = updatedEntry
            }
        } else {
            let newEntry = JournalEntry(
                id: UUID().uuidString,
                plannedDateIdentifier: plannedDate.id,
                rating: clampedRating,
                notes: notes,
                createdDate: .now
            )

            let result = await repository.createJournalEntry(newEntry, for: plannedDate)
            if case .success(let created) = result {
                entry = created
            }
        }
    }
}
