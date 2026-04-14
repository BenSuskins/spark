import Foundation
import SwiftData

@MainActor
final class SyncManager {
    private let modelContainer: ModelContainer
    private let remoteDateRepository: DateRepository
    private let remoteGroupRepository: GroupRepository

    private var context: ModelContext { modelContainer.mainContext }

    init(modelContainer: ModelContainer, remoteDateRepository: DateRepository, remoteGroupRepository: GroupRepository) {
        self.modelContainer = modelContainer
        self.remoteDateRepository = remoteDateRepository
        self.remoteGroupRepository = remoteGroupRepository
    }

    func syncPendingChanges() async {
        await syncPendingIdeas()
        await syncPendingVotes()
        await syncPendingPlannedDates()
        await syncPendingItinerarySteps()
        await syncPendingJournalEntries()
    }

    private func syncPendingIdeas() async {
        let pending = SyncStatus.pending.rawValue
        let descriptor = FetchDescriptor<PersistedIdea>(predicate: #Predicate { $0.syncStatus == pending })
        guard let ideas = try? context.fetch(descriptor) else { return }

        for persisted in ideas {
            guard let idea = persisted.toModel() else { continue }
            let result = await remoteDateRepository.createIdea(idea, in: idea.groupIdentifier)
            if case .success = result {
                persisted.syncStatus = SyncStatus.synced.rawValue
            } else {
                persisted.syncStatus = SyncStatus.failed.rawValue
            }
        }
        try? context.save()
    }

    private func syncPendingVotes() async {
        let pending = SyncStatus.pending.rawValue
        let descriptor = FetchDescriptor<PersistedVote>(predicate: #Predicate { $0.syncStatus == pending })
        guard let votes = try? context.fetch(descriptor) else { return }

        for persisted in votes {
            let vote = persisted.toModel()
            // We need an Idea to cast the vote — fetch the idea from cache
            let ideaId = persisted.ideaIdentifier

            let ideaDescriptor = FetchDescriptor<PersistedIdea>(
                predicate: #Predicate { $0.identifier == ideaId }
            )
            guard let persistedIdea = try? context.fetch(ideaDescriptor).first,
                  let idea = persistedIdea.toModel() else { continue }

            let result = await remoteDateRepository.castVote(vote, on: idea)
            if case .success = result {
                persisted.syncStatus = SyncStatus.synced.rawValue
            } else {
                persisted.syncStatus = SyncStatus.failed.rawValue
            }
        }
        try? context.save()
    }

    private func syncPendingPlannedDates() async {
        let pending = SyncStatus.pending.rawValue
        let descriptor = FetchDescriptor<PersistedPlannedDate>(predicate: #Predicate { $0.syncStatus == pending })
        guard let dates = try? context.fetch(descriptor) else { return }

        for persisted in dates {
            guard let plannedDate = persisted.toModel() else { continue }
            let result = await remoteDateRepository.createPlannedDate(plannedDate, in: persisted.groupIdentifier)
            if case .success = result {
                persisted.syncStatus = SyncStatus.synced.rawValue
            } else {
                persisted.syncStatus = SyncStatus.failed.rawValue
            }
        }
        try? context.save()
    }

    private func syncPendingItinerarySteps() async {
        let pending = SyncStatus.pending.rawValue
        let descriptor = FetchDescriptor<PersistedItineraryStep>(predicate: #Predicate { $0.syncStatus == pending })
        guard let steps = try? context.fetch(descriptor) else { return }

        for persisted in steps {
            let step = persisted.toModel()
            // Find the planned date for this step
            let plannedDateId = persisted.plannedDateIdentifier

            let dateDescriptor = FetchDescriptor<PersistedPlannedDate>(
                predicate: #Predicate { $0.identifier == plannedDateId }
            )
            guard let persistedDate = try? context.fetch(dateDescriptor).first,
                  let plannedDate = persistedDate.toModel() else { continue }

            let result = await remoteDateRepository.createItineraryStep(step, for: plannedDate)
            if case .success = result {
                persisted.syncStatus = SyncStatus.synced.rawValue
            } else {
                persisted.syncStatus = SyncStatus.failed.rawValue
            }
        }
        try? context.save()
    }

    private func syncPendingJournalEntries() async {
        let pending = SyncStatus.pending.rawValue
        let descriptor = FetchDescriptor<PersistedJournalEntry>(predicate: #Predicate { $0.syncStatus == pending })
        guard let entries = try? context.fetch(descriptor) else { return }

        for persisted in entries {
            let entry = persisted.toModel()
            let plannedDateId = persisted.plannedDateIdentifier

            let dateDescriptor = FetchDescriptor<PersistedPlannedDate>(
                predicate: #Predicate { $0.identifier == plannedDateId }
            )
            guard let persistedDate = try? context.fetch(dateDescriptor).first,
                  let plannedDate = persistedDate.toModel() else { continue }

            let result = await remoteDateRepository.createJournalEntry(entry, for: plannedDate)
            if case .success = result {
                persisted.syncStatus = SyncStatus.synced.rawValue
            } else {
                persisted.syncStatus = SyncStatus.failed.rawValue
            }
        }
        try? context.save()
    }
}
