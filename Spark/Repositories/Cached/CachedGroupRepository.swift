import Foundation
import SwiftData

final class CachedGroupRepository: GroupRepository, @unchecked Sendable {
    private let remote: GroupRepository
    private let modelContainer: ModelContainer

    init(remote: GroupRepository, modelContainer: ModelContainer) {
        self.remote = remote
        self.modelContainer = modelContainer
    }

    @MainActor
    private var context: ModelContext { modelContainer.mainContext }
    @MainActor private var activeSyncTask: Task<Void, Never>?

    @MainActor
    private func enqueueSync(_ work: @escaping @MainActor () async -> Void) {
        let previous = activeSyncTask
        activeSyncTask = Task { @MainActor in
            await previous?.value
            await work()
        }
    }

    func fetchGroups() async -> Result<[Group], SparkError> {
        let cached = await fetchCachedGroups()

        await enqueueSync { [self] in await syncGroupsFromRemote() }

        return .success(cached)
    }

    func createGroup(name: String, emoji: String) async -> Result<Group, SparkError> {
        let remoteResult = await remote.createGroup(name: name, emoji: emoji)

        if case .success(let group) = remoteResult {
            await cacheGroup(group, syncStatus: .synced)
        }

        return remoteResult
    }
        
    func updateGroup(_ group: Group) async -> Result<Group, SparkError> {
        let remoteResult = await remote.updateGroup(group)

        if case .success(let updated) = remoteResult {
            await cacheGroup(updated, syncStatus: .synced)
        }

        return remoteResult
    }

    func deleteGroup(_ group: Group) async -> Result<Void, SparkError> {
        await deleteCachedGroup(group.id)

        let remoteResult = await remote.deleteGroup(group)
        if case .failure = remoteResult {
            // Re-cache if remote delete fails
            await cacheGroup(group, syncStatus: .synced)
        }

        return remoteResult
    }

    func shareGroup(_ group: Group) async -> Result<URL, SparkError> {
        await remote.shareGroup(group)
    }

    func acceptShare(from url: URL) async -> Result<Group, SparkError> {
        let result = await remote.acceptShare(from: url)

        if case .success(let group) = result {
            await cacheGroup(group, syncStatus: .synced)
        }

        return result
    }

    // MARK: - Cache Operations

    @MainActor
    private func fetchCachedGroups() -> [Group] {
        let descriptor = FetchDescriptor<PersistedGroup>()
        let persisted = (try? context.fetch(descriptor)) ?? []
        return persisted.map { $0.toModel() }
    }

    @MainActor
    private func cacheGroup(_ group: Group, syncStatus: SyncStatus) {
        let groupId = group.id
        let descriptor = FetchDescriptor<PersistedGroup>(predicate: #Predicate { $0.identifier == groupId })
        if let existing = try? context.fetch(descriptor).first {
            existing.update(from: group)
            existing.syncStatus = syncStatus.rawValue
        } else {
            context.insert(PersistedGroup(from: group, syncStatus: syncStatus))
        }
        try? context.save()
    }

    @MainActor
    private func deleteCachedGroup(_ identifier: String) {
        deleteCachedEntitiesForGroup(identifier)

        let descriptor = FetchDescriptor<PersistedGroup>(predicate: #Predicate { $0.identifier == identifier })
        if let existing = try? context.fetch(descriptor).first {
            context.delete(existing)
        }
        try? context.save()
    }

    @MainActor
    private func deleteCachedEntitiesForGroup(_ groupIdentifier: String) {
        let votesDescriptor = FetchDescriptor<PersistedVote>(predicate: #Predicate { $0.groupIdentifier == groupIdentifier })
        for vote in (try? context.fetch(votesDescriptor)) ?? [] { context.delete(vote) }

        let ideasDescriptor = FetchDescriptor<PersistedIdea>(predicate: #Predicate { $0.groupIdentifier == groupIdentifier })
        for idea in (try? context.fetch(ideasDescriptor)) ?? [] { context.delete(idea) }

        let stepsDescriptor = FetchDescriptor<PersistedItineraryStep>(predicate: #Predicate { $0.groupIdentifier == groupIdentifier })
        for step in (try? context.fetch(stepsDescriptor)) ?? [] { context.delete(step) }

        let journalDescriptor = FetchDescriptor<PersistedJournalEntry>(predicate: #Predicate { $0.groupIdentifier == groupIdentifier })
        for entry in (try? context.fetch(journalDescriptor)) ?? [] { context.delete(entry) }

        let datesDescriptor = FetchDescriptor<PersistedPlannedDate>(predicate: #Predicate { $0.groupIdentifier == groupIdentifier })
        for date in (try? context.fetch(datesDescriptor)) ?? [] { context.delete(date) }
    }

    @MainActor
    private func syncGroupsFromRemote() async {
        let result = await remote.fetchGroups()
        guard case .success(let groups) = result else { return }

        // Replace all cached groups with remote data
        let descriptor = FetchDescriptor<PersistedGroup>()
        let existing = (try? context.fetch(descriptor)) ?? []
        let existingById = Dictionary(uniqueKeysWithValues: existing.map { ($0.identifier, $0) })

        var remoteIds = Set<String>()
        for group in groups {
            remoteIds.insert(group.id)
            if let persisted = existingById[group.id] {
                persisted.update(from: group)
                persisted.syncStatus = SyncStatus.synced.rawValue
            } else {
                context.insert(PersistedGroup(from: group, syncStatus: .synced))
            }
        }

        // Remove groups that no longer exist remotely (unless pending sync)
        for persisted in existing where !remoteIds.contains(persisted.identifier) && persisted.syncStatus != SyncStatus.pending.rawValue && persisted.syncStatus != SyncStatus.pendingDeletion.rawValue {
            context.delete(persisted)
        }

        try? context.save()
    }
}
