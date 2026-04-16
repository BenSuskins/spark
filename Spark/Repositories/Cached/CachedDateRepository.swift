import Foundation
import SwiftData

final class CachedDateRepository: DateRepository, @unchecked Sendable {
    private let remote: DateRepository
    private let modelContainer: ModelContainer
    @MainActor private var activeSyncTask: Task<Void, Never>?

    init(remote: DateRepository, modelContainer: ModelContainer) {
        self.remote = remote
        self.modelContainer = modelContainer
    }

    @MainActor
    private var context: ModelContext { modelContainer.mainContext }

    @MainActor
    private func enqueueSync(_ work: @escaping @MainActor () async -> Void) {
        let previous = activeSyncTask
        activeSyncTask = Task { @MainActor in
            await previous?.value
            await work()
        }
    }

    // MARK: - Ideas

    func fetchIdeas(for groupIdentifier: String) async -> Result<[Idea], SparkError> {
        let cached = await fetchCachedIdeas(for: groupIdentifier)

        await enqueueSync { [self] in await syncIdeasFromRemote(for: groupIdentifier) }

        return .success(cached)
    }

    func createIdea(_ idea: Idea, in groupIdentifier: String) async -> Result<Idea, SparkError> {
        await cacheIdea(idea, syncStatus: .pending)

        let remoteResult = await remote.createIdea(idea, in: groupIdentifier)
        if case .success(let saved) = remoteResult {
            await cacheIdea(saved, syncStatus: .synced)
            return .success(saved)
        } else if case .failure(.networkUnavailable) = remoteResult {
            return .success(idea)
        }

        return remoteResult
    }

    func updateIdea(_ idea: Idea) async -> Result<Idea, SparkError> {
        await cacheIdea(idea, syncStatus: .pending)

        let remoteResult = await remote.updateIdea(idea)
        if case .success(let saved) = remoteResult {
            await cacheIdea(saved, syncStatus: .synced)
            return .success(saved)
        } else if case .failure(.networkUnavailable) = remoteResult {
            return .success(idea)
        }

        return remoteResult
    }

    func deleteIdea(_ idea: Idea) async -> Result<Void, SparkError> {
        let remoteResult = await remote.deleteIdea(idea)

        if case .success = remoteResult {
            await deleteCachedIdea(idea.id)
        } else if case .failure(.networkUnavailable) = remoteResult {
            await markCachedIdeaForDeletion(idea.id)
            return .success(())
        }

        return remoteResult
    }

    // MARK: - Votes

    func castVote(_ vote: Vote, on idea: Idea) async -> Result<Vote, SparkError> {
        await cacheVote(vote, groupIdentifier: idea.groupIdentifier, syncStatus: .pending)

        let remoteResult = await remote.castVote(vote, on: idea)
        if case .success(let saved) = remoteResult {
            await cacheVote(saved, groupIdentifier: idea.groupIdentifier, syncStatus: .synced)
            return .success(saved)
        } else if case .failure(.networkUnavailable) = remoteResult {
            return .success(vote)
        }

        return remoteResult
    }

    func removeVote(_ vote: Vote, in groupIdentifier: String) async -> Result<Void, SparkError> {
        let remoteResult = await remote.removeVote(vote, in: groupIdentifier)

        if case .success = remoteResult {
            await deleteCachedVoteByUser(vote.ideaIdentifier, userIdentifier: vote.userIdentifier)
        } else if case .failure(.networkUnavailable) = remoteResult {
            await markCachedVoteForDeletion(vote.ideaIdentifier, userIdentifier: vote.userIdentifier)
            return .success(())
        }

        return remoteResult
    }

    func votesForIdea(_ ideaIdentifier: String) async -> [Vote] {
        await fetchCachedVotesForIdea(ideaIdentifier)
    }

    func fetchAllVotes(for groupIdentifier: String) async -> Result<[String: [Vote]], SparkError> {
        let cached = await fetchCachedAllVotes(for: groupIdentifier)

        await enqueueSync { [self] in await syncVotesFromRemote(for: groupIdentifier) }

        return .success(cached)
    }

    // MARK: - Planned Dates

    func fetchUpcomingDates(for groupIdentifier: String) async -> Result<[PlannedDate], SparkError> {
        let cached = await fetchCachedUpcomingDates(for: groupIdentifier)

        await enqueueSync { [self] in await syncPlannedDatesFromRemote(for: groupIdentifier) }

        return .success(cached)
    }

    func fetchPastDates(for groupIdentifier: String) async -> Result<[PlannedDate], SparkError> {
        let cached = await fetchCachedPastDates(for: groupIdentifier)

        await enqueueSync { [self] in await syncPlannedDatesFromRemote(for: groupIdentifier) }

        return .success(cached)
    }

    func createPlannedDate(_ plannedDate: PlannedDate, in groupIdentifier: String) async -> Result<PlannedDate, SparkError> {
        await cachePlannedDate(plannedDate, syncStatus: .pending)

        let remoteResult = await remote.createPlannedDate(plannedDate, in: groupIdentifier)
        if case .success(let saved) = remoteResult {
            await cachePlannedDate(saved, syncStatus: .synced)
            return .success(saved)
        } else if case .failure(.networkUnavailable) = remoteResult {
            return .success(plannedDate)
        }

        return remoteResult
    }

    func updatePlannedDate(_ plannedDate: PlannedDate) async -> Result<PlannedDate, SparkError> {
        await cachePlannedDate(plannedDate, syncStatus: .pending)

        let remoteResult = await remote.updatePlannedDate(plannedDate)
        if case .success(let saved) = remoteResult {
            await cachePlannedDate(saved, syncStatus: .synced)
            return .success(saved)
        } else if case .failure(.networkUnavailable) = remoteResult {
            return .success(plannedDate)
        }

        return remoteResult
    }

    func deletePlannedDate(_ plannedDate: PlannedDate) async -> Result<Void, SparkError> {
        let remoteResult = await remote.deletePlannedDate(plannedDate)

        if case .success = remoteResult {
            await deleteCachedPlannedDate(plannedDate.id)
        } else if case .failure(.networkUnavailable) = remoteResult {
            await markCachedPlannedDateForDeletion(plannedDate.id)
            return .success(())
        }

        return remoteResult
    }

    // MARK: - Itinerary Steps

    func fetchItinerarySteps(for plannedDate: PlannedDate) async -> Result<[ItineraryStep], SparkError> {
        let cached = await fetchCachedItinerarySteps(for: plannedDate.id)

        await enqueueSync { [self] in await syncItineraryStepsFromRemote(for: plannedDate) }

        return .success(cached)
    }

    func createItineraryStep(_ step: ItineraryStep, for plannedDate: PlannedDate) async -> Result<ItineraryStep, SparkError> {
        await cacheItineraryStep(step, groupIdentifier: plannedDate.groupIdentifier, syncStatus: .pending)

        let remoteResult = await remote.createItineraryStep(step, for: plannedDate)
        if case .success(let saved) = remoteResult {
            await cacheItineraryStep(saved, groupIdentifier: plannedDate.groupIdentifier, syncStatus: .synced)
            return .success(saved)
        } else if case .failure(.networkUnavailable) = remoteResult {
            return .success(step)
        }

        return remoteResult
    }

    func updateItineraryStep(_ step: ItineraryStep) async -> Result<ItineraryStep, SparkError> {
        await updateCachedItineraryStep(step, syncStatus: .pending)

        let remoteResult = await remote.updateItineraryStep(step)
        if case .success(let saved) = remoteResult {
            await updateCachedItineraryStep(saved, syncStatus: .synced)
            return .success(saved)
        } else if case .failure(.networkUnavailable) = remoteResult {
            return .success(step)
        }

        return remoteResult
    }

    func deleteItineraryStep(_ step: ItineraryStep) async -> Result<Void, SparkError> {
        let remoteResult = await remote.deleteItineraryStep(step)

        if case .success = remoteResult {
            await deleteCachedItineraryStep(step.id)
        } else if case .failure(.networkUnavailable) = remoteResult {
            await markCachedItineraryStepForDeletion(step.id)
            return .success(())
        }

        return remoteResult
    }

    // MARK: - Journal Entries

    func fetchJournalEntry(for plannedDate: PlannedDate) async -> Result<JournalEntry?, SparkError> {
        let cached = await fetchCachedJournalEntry(for: plannedDate.id)

        await enqueueSync { [self] in await syncJournalEntryFromRemote(for: plannedDate) }

        return .success(cached)
    }

    func createJournalEntry(_ entry: JournalEntry, for plannedDate: PlannedDate) async -> Result<JournalEntry, SparkError> {
        await cacheJournalEntry(entry, groupIdentifier: plannedDate.groupIdentifier, syncStatus: .pending)

        let remoteResult = await remote.createJournalEntry(entry, for: plannedDate)
        if case .success(let saved) = remoteResult {
            await cacheJournalEntry(saved, groupIdentifier: plannedDate.groupIdentifier, syncStatus: .synced)
            return .success(saved)
        } else if case .failure(.networkUnavailable) = remoteResult {
            return .success(entry)
        }

        return remoteResult
    }

    func updateJournalEntry(_ entry: JournalEntry) async -> Result<JournalEntry, SparkError> {
        await updateCachedJournalEntry(entry, syncStatus: .pending)

        let remoteResult = await remote.updateJournalEntry(entry)
        if case .success(let saved) = remoteResult {
            await updateCachedJournalEntry(saved, syncStatus: .synced)
            return .success(saved)
        } else if case .failure(.networkUnavailable) = remoteResult {
            return .success(entry)
        }

        return remoteResult
    }
}

// MARK: - Cache Helpers

extension CachedDateRepository {

    // MARK: Ideas

    @MainActor
    private func fetchCachedIdeas(for groupIdentifier: String) -> [Idea] {
        let deleted = SyncStatus.pendingDeletion.rawValue
        let descriptor = FetchDescriptor<PersistedIdea>(predicate: #Predicate {
            $0.groupIdentifier == groupIdentifier && $0.syncStatus != deleted
        })
        let persisted = (try? context.fetch(descriptor)) ?? []
        return persisted.compactMap { $0.toModel() }
    }

    @MainActor
    private func cacheIdea(_ idea: Idea, syncStatus: SyncStatus) {
        let ideaId = idea.id
        let descriptor = FetchDescriptor<PersistedIdea>(predicate: #Predicate { $0.identifier == ideaId })
        if let existing = try? context.fetch(descriptor).first {
            existing.update(from: idea)
            existing.syncStatus = syncStatus.rawValue
        } else {
            context.insert(PersistedIdea(from: idea, syncStatus: syncStatus))
        }
        try? context.save()
    }

    @MainActor
    private func deleteCachedIdea(_ identifier: String) {
        let voteDescriptor = FetchDescriptor<PersistedVote>(predicate: #Predicate { $0.ideaIdentifier == identifier })
        for vote in (try? context.fetch(voteDescriptor)) ?? [] {
            context.delete(vote)
        }

        let descriptor = FetchDescriptor<PersistedIdea>(predicate: #Predicate { $0.identifier == identifier })
        if let existing = try? context.fetch(descriptor).first {
            context.delete(existing)
        }
        try? context.save()
    }

    @MainActor
    private func markCachedIdeaForDeletion(_ identifier: String) {
        let voteDescriptor = FetchDescriptor<PersistedVote>(predicate: #Predicate { $0.ideaIdentifier == identifier })
        for vote in (try? context.fetch(voteDescriptor)) ?? [] {
            vote.syncStatus = SyncStatus.pendingDeletion.rawValue
        }

        let descriptor = FetchDescriptor<PersistedIdea>(predicate: #Predicate { $0.identifier == identifier })
        if let existing = try? context.fetch(descriptor).first {
            existing.syncStatus = SyncStatus.pendingDeletion.rawValue
        }
        try? context.save()
    }

    @MainActor
    private func syncIdeasFromRemote(for groupIdentifier: String) async {
        let result = await remote.fetchIdeas(for: groupIdentifier)
        guard case .success(let ideas) = result else { return }

        let descriptor = FetchDescriptor<PersistedIdea>(predicate: #Predicate { $0.groupIdentifier == groupIdentifier })
        let existing = (try? context.fetch(descriptor)) ?? []
        let existingById = Dictionary(uniqueKeysWithValues: existing.map { ($0.identifier, $0) })

        var remoteIds = Set<String>()
        for idea in ideas {
            remoteIds.insert(idea.id)
            if let persisted = existingById[idea.id] {
                persisted.update(from: idea)
                persisted.syncStatus = SyncStatus.synced.rawValue
            } else {
                context.insert(PersistedIdea(from: idea, syncStatus: .synced))
            }
        }

        for persisted in existing where !remoteIds.contains(persisted.identifier) && persisted.syncStatus != SyncStatus.pending.rawValue && persisted.syncStatus != SyncStatus.pendingDeletion.rawValue {
            context.delete(persisted)
        }

        try? context.save()
    }

    // MARK: Votes

    @MainActor
    private func fetchCachedVotesForIdea(_ ideaIdentifier: String) -> [Vote] {
        let deleted = SyncStatus.pendingDeletion.rawValue
        let descriptor = FetchDescriptor<PersistedVote>(predicate: #Predicate {
            $0.ideaIdentifier == ideaIdentifier && $0.syncStatus != deleted
        })
        let persisted = (try? context.fetch(descriptor)) ?? []
        return persisted.map { $0.toModel() }
    }

    @MainActor
    private func fetchCachedAllVotes(for groupIdentifier: String) -> [String: [Vote]] {
        let deleted = SyncStatus.pendingDeletion.rawValue
        let descriptor = FetchDescriptor<PersistedVote>(predicate: #Predicate {
            $0.groupIdentifier == groupIdentifier && $0.syncStatus != deleted
        })
        let persisted = (try? context.fetch(descriptor)) ?? []
        let votes = persisted.map { $0.toModel() }
        return Dictionary(grouping: votes, by: \.ideaIdentifier)
    }

    @MainActor
    private func cacheVote(_ vote: Vote, groupIdentifier: String, syncStatus: SyncStatus) {
        let ideaId = vote.ideaIdentifier
        let userId = vote.userIdentifier
        let descriptor = FetchDescriptor<PersistedVote>(predicate: #Predicate {
            $0.ideaIdentifier == ideaId && $0.userIdentifier == userId
        })
        if let existing = try? context.fetch(descriptor).first {
            existing.update(from: vote)
            existing.syncStatus = syncStatus.rawValue
        } else {
            context.insert(PersistedVote(from: vote, groupIdentifier: groupIdentifier, syncStatus: syncStatus))
        }
        try? context.save()
    }

    @MainActor
    private func deleteCachedVote(_ identifier: String) {
        let descriptor = FetchDescriptor<PersistedVote>(predicate: #Predicate { $0.identifier == identifier })
        if let existing = try? context.fetch(descriptor).first {
            context.delete(existing)
            try? context.save()
        }
    }

    @MainActor
    private func deleteCachedVoteByUser(_ ideaIdentifier: String, userIdentifier: String) {
        let descriptor = FetchDescriptor<PersistedVote>(predicate: #Predicate {
            $0.ideaIdentifier == ideaIdentifier && $0.userIdentifier == userIdentifier
        })
        let existing = (try? context.fetch(descriptor)) ?? []
        for vote in existing {
            context.delete(vote)
        }
        try? context.save()
    }

    @MainActor
    private func markCachedVoteForDeletion(_ ideaIdentifier: String, userIdentifier: String) {
        let descriptor = FetchDescriptor<PersistedVote>(predicate: #Predicate {
            $0.ideaIdentifier == ideaIdentifier && $0.userIdentifier == userIdentifier
        })
        for vote in (try? context.fetch(descriptor)) ?? [] {
            vote.syncStatus = SyncStatus.pendingDeletion.rawValue
        }
        try? context.save()
    }

    @MainActor
    private func syncVotesFromRemote(for groupIdentifier: String) async {
        let result = await remote.fetchAllVotes(for: groupIdentifier)
        guard case .success(let votesByIdea) = result else { return }

        let descriptor = FetchDescriptor<PersistedVote>(predicate: #Predicate { $0.groupIdentifier == groupIdentifier })
        let existing = (try? context.fetch(descriptor)) ?? []
        let existingById = Dictionary(uniqueKeysWithValues: existing.map { ($0.identifier, $0) })

        var remoteIds = Set<String>()
        for votes in votesByIdea.values {
            for vote in votes {
                remoteIds.insert(vote.id)
                if let persisted = existingById[vote.id] {
                    persisted.update(from: vote)
                    persisted.syncStatus = SyncStatus.synced.rawValue
                } else {
                    context.insert(PersistedVote(from: vote, groupIdentifier: groupIdentifier, syncStatus: .synced))
                }
            }
        }

        for persisted in existing where !remoteIds.contains(persisted.identifier) && persisted.syncStatus != SyncStatus.pending.rawValue && persisted.syncStatus != SyncStatus.pendingDeletion.rawValue {
            context.delete(persisted)
        }

        try? context.save()
    }

    // MARK: Planned Dates

    @MainActor
    private func fetchCachedUpcomingDates(for groupIdentifier: String) -> [PlannedDate] {
        let now = Date.now
        let planned = DateStatus.planned.rawValue
        let deleted = SyncStatus.pendingDeletion.rawValue
        let descriptor = FetchDescriptor<PersistedPlannedDate>(predicate: #Predicate {
            $0.groupIdentifier == groupIdentifier && $0.status == planned && $0.date >= now && $0.syncStatus != deleted
        })
        let persisted = (try? context.fetch(descriptor)) ?? []
        return persisted.compactMap { $0.toModel() }.sorted { $0.date < $1.date }
    }

    @MainActor
    private func fetchCachedPastDates(for groupIdentifier: String) -> [PlannedDate] {
        let now = Date.now
        let completed = DateStatus.completed.rawValue
        let deleted = SyncStatus.pendingDeletion.rawValue
        let descriptor = FetchDescriptor<PersistedPlannedDate>(predicate: #Predicate {
            $0.groupIdentifier == groupIdentifier && ($0.status == completed || $0.date < now) && $0.syncStatus != deleted
        })
        let persisted = (try? context.fetch(descriptor)) ?? []
        return persisted.compactMap { $0.toModel() }.sorted { $0.date > $1.date }
    }

    @MainActor
    private func cachePlannedDate(_ plannedDate: PlannedDate, syncStatus: SyncStatus) {
        let dateId = plannedDate.id
        let descriptor = FetchDescriptor<PersistedPlannedDate>(predicate: #Predicate { $0.identifier == dateId })
        if let existing = try? context.fetch(descriptor).first {
            existing.update(from: plannedDate)
            existing.syncStatus = syncStatus.rawValue
        } else {
            context.insert(PersistedPlannedDate(from: plannedDate, syncStatus: syncStatus))
        }
        try? context.save()
    }

    @MainActor
    private func deleteCachedPlannedDate(_ identifier: String) {
        let stepsDescriptor = FetchDescriptor<PersistedItineraryStep>(predicate: #Predicate { $0.plannedDateIdentifier == identifier })
        for step in (try? context.fetch(stepsDescriptor)) ?? [] {
            context.delete(step)
        }

        let journalDescriptor = FetchDescriptor<PersistedJournalEntry>(predicate: #Predicate { $0.plannedDateIdentifier == identifier })
        for entry in (try? context.fetch(journalDescriptor)) ?? [] {
            context.delete(entry)
        }

        let descriptor = FetchDescriptor<PersistedPlannedDate>(predicate: #Predicate { $0.identifier == identifier })
        if let existing = try? context.fetch(descriptor).first {
            context.delete(existing)
        }
        try? context.save()
    }

    @MainActor
    private func markCachedPlannedDateForDeletion(_ identifier: String) {
        let stepsDescriptor = FetchDescriptor<PersistedItineraryStep>(predicate: #Predicate { $0.plannedDateIdentifier == identifier })
        for step in (try? context.fetch(stepsDescriptor)) ?? [] {
            step.syncStatus = SyncStatus.pendingDeletion.rawValue
        }

        let journalDescriptor = FetchDescriptor<PersistedJournalEntry>(predicate: #Predicate { $0.plannedDateIdentifier == identifier })
        for entry in (try? context.fetch(journalDescriptor)) ?? [] {
            entry.syncStatus = SyncStatus.pendingDeletion.rawValue
        }

        let descriptor = FetchDescriptor<PersistedPlannedDate>(predicate: #Predicate { $0.identifier == identifier })
        if let existing = try? context.fetch(descriptor).first {
            existing.syncStatus = SyncStatus.pendingDeletion.rawValue
        }
        try? context.save()
    }

    @MainActor
    private func syncPlannedDatesFromRemote(for groupIdentifier: String) async {
        async let upcomingResult = remote.fetchUpcomingDates(for: groupIdentifier)
        async let pastResult = remote.fetchPastDates(for: groupIdentifier)

        var allDates: [PlannedDate] = []
        if case .success(let upcoming) = await upcomingResult { allDates.append(contentsOf: upcoming) }
        if case .success(let past) = await pastResult { allDates.append(contentsOf: past) }

        guard !allDates.isEmpty else { return }

        let descriptor = FetchDescriptor<PersistedPlannedDate>(predicate: #Predicate { $0.groupIdentifier == groupIdentifier })
        let existing = (try? context.fetch(descriptor)) ?? []
        let existingById = Dictionary(uniqueKeysWithValues: existing.map { ($0.identifier, $0) })

        var remoteIds = Set<String>()
        for date in allDates {
            remoteIds.insert(date.id)
            if let persisted = existingById[date.id] {
                persisted.update(from: date)
                persisted.syncStatus = SyncStatus.synced.rawValue
            } else {
                context.insert(PersistedPlannedDate(from: date, syncStatus: .synced))
            }
        }

        for persisted in existing where !remoteIds.contains(persisted.identifier) && persisted.syncStatus != SyncStatus.pending.rawValue && persisted.syncStatus != SyncStatus.pendingDeletion.rawValue {
            context.delete(persisted)
        }

        try? context.save()
    }

    // MARK: Itinerary Steps

    @MainActor
    private func fetchCachedItinerarySteps(for plannedDateIdentifier: String) -> [ItineraryStep] {
        let deleted = SyncStatus.pendingDeletion.rawValue
        let descriptor = FetchDescriptor<PersistedItineraryStep>(predicate: #Predicate {
            $0.plannedDateIdentifier == plannedDateIdentifier && $0.syncStatus != deleted
        })
        let persisted = (try? context.fetch(descriptor)) ?? []
        return persisted.map { $0.toModel() }.sorted { $0.order < $1.order }
    }

    @MainActor
    private func cacheItineraryStep(_ step: ItineraryStep, groupIdentifier: String, syncStatus: SyncStatus) {
        let stepId = step.id
        let descriptor = FetchDescriptor<PersistedItineraryStep>(predicate: #Predicate { $0.identifier == stepId })
        if let existing = try? context.fetch(descriptor).first {
            existing.update(from: step)
            existing.syncStatus = syncStatus.rawValue
        } else {
            context.insert(PersistedItineraryStep(from: step, groupIdentifier: groupIdentifier, syncStatus: syncStatus))
        }
        try? context.save()
    }

    @MainActor
    private func updateCachedItineraryStep(_ step: ItineraryStep, syncStatus: SyncStatus = .synced) {
        let stepId = step.id
        let descriptor = FetchDescriptor<PersistedItineraryStep>(predicate: #Predicate { $0.identifier == stepId })
        if let existing = try? context.fetch(descriptor).first {
            existing.update(from: step)
            existing.syncStatus = syncStatus.rawValue
            try? context.save()
        }
    }

    @MainActor
    private func deleteCachedItineraryStep(_ identifier: String) {
        let descriptor = FetchDescriptor<PersistedItineraryStep>(predicate: #Predicate { $0.identifier == identifier })
        if let existing = try? context.fetch(descriptor).first {
            context.delete(existing)
            try? context.save()
        }
    }

    @MainActor
    private func markCachedItineraryStepForDeletion(_ identifier: String) {
        let descriptor = FetchDescriptor<PersistedItineraryStep>(predicate: #Predicate { $0.identifier == identifier })
        if let existing = try? context.fetch(descriptor).first {
            existing.syncStatus = SyncStatus.pendingDeletion.rawValue
            try? context.save()
        }
    }

    @MainActor
    private func syncItineraryStepsFromRemote(for plannedDate: PlannedDate) async {
        let result = await remote.fetchItinerarySteps(for: plannedDate)
        guard case .success(let steps) = result else { return }

        let plannedDateId = plannedDate.id
        let descriptor = FetchDescriptor<PersistedItineraryStep>(predicate: #Predicate { $0.plannedDateIdentifier == plannedDateId })
        let existing = (try? context.fetch(descriptor)) ?? []
        let existingById = Dictionary(uniqueKeysWithValues: existing.map { ($0.identifier, $0) })

        var remoteIds = Set<String>()
        for step in steps {
            remoteIds.insert(step.id)
            if let persisted = existingById[step.id] {
                persisted.update(from: step)
                persisted.syncStatus = SyncStatus.synced.rawValue
            } else {
                context.insert(PersistedItineraryStep(from: step, groupIdentifier: plannedDate.groupIdentifier, syncStatus: .synced))
            }
        }

        for persisted in existing where !remoteIds.contains(persisted.identifier) && persisted.syncStatus != SyncStatus.pending.rawValue && persisted.syncStatus != SyncStatus.pendingDeletion.rawValue {
            context.delete(persisted)
        }

        try? context.save()
    }

    // MARK: Journal Entries

    @MainActor
    private func fetchCachedJournalEntry(for plannedDateIdentifier: String) -> JournalEntry? {
        let deleted = SyncStatus.pendingDeletion.rawValue
        let descriptor = FetchDescriptor<PersistedJournalEntry>(predicate: #Predicate {
            $0.plannedDateIdentifier == plannedDateIdentifier && $0.syncStatus != deleted
        })
        return (try? context.fetch(descriptor).first)?.toModel()
    }

    @MainActor
    private func cacheJournalEntry(_ entry: JournalEntry, groupIdentifier: String, syncStatus: SyncStatus) {
        let entryId = entry.id
        let descriptor = FetchDescriptor<PersistedJournalEntry>(predicate: #Predicate { $0.identifier == entryId })
        if let existing = try? context.fetch(descriptor).first {
            existing.update(from: entry)
            existing.syncStatus = syncStatus.rawValue
        } else {
            context.insert(PersistedJournalEntry(from: entry, groupIdentifier: groupIdentifier, syncStatus: syncStatus))
        }
        try? context.save()
    }

    @MainActor
    private func updateCachedJournalEntry(_ entry: JournalEntry, syncStatus: SyncStatus = .synced) {
        let entryId = entry.id
        let descriptor = FetchDescriptor<PersistedJournalEntry>(predicate: #Predicate { $0.identifier == entryId })
        if let existing = try? context.fetch(descriptor).first {
            existing.update(from: entry)
            existing.syncStatus = syncStatus.rawValue
            try? context.save()
        }
    }

    @MainActor
    private func syncJournalEntryFromRemote(for plannedDate: PlannedDate) async {
        let result = await remote.fetchJournalEntry(for: plannedDate)
        guard case .success(let entry) = result, let entry else { return }

        let entryId = entry.id
        let descriptor = FetchDescriptor<PersistedJournalEntry>(predicate: #Predicate { $0.identifier == entryId })
        if let existing = try? context.fetch(descriptor).first {
            existing.update(from: entry)
            existing.syncStatus = SyncStatus.synced.rawValue
        } else {
            context.insert(PersistedJournalEntry(from: entry, groupIdentifier: plannedDate.groupIdentifier, syncStatus: .synced))
        }
        try? context.save()
    }
}
