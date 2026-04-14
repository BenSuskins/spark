import Foundation
import SwiftData

enum PersistenceContainer {
    static func create() throws -> ModelContainer {
        let schema = Schema([
            PersistedGroup.self,
            PersistedIdea.self,
            PersistedVote.self,
            PersistedPlannedDate.self,
            PersistedItineraryStep.self,
            PersistedJournalEntry.self
        ])

        let configuration = ModelConfiguration(isStoredInMemoryOnly: false, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func createInMemory() throws -> ModelContainer {
        let schema = Schema([
            PersistedGroup.self,
            PersistedIdea.self,
            PersistedVote.self,
            PersistedPlannedDate.self,
            PersistedItineraryStep.self,
            PersistedJournalEntry.self
        ])

        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
