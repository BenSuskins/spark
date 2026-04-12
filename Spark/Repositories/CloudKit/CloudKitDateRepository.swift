import Foundation
import CloudKit

final class CloudKitDateRepository: DateRepository, @unchecked Sendable {
    private let manager: CloudKitManager

    init(manager: CloudKitManager = CloudKitManager()) {
        self.manager = manager
    }

    // MARK: - Ideas

    func fetchIdeas(for groupIdentifier: String) async -> Result<[Idea], SparkError> {
        let zoneID = manager.zoneID(for: groupIdentifier)
        let database = manager.databaseForZone(zoneID)
        let predicate = NSPredicate(format: "groupIdentifier == %@", groupIdentifier)

        let result = await manager.fetch(recordType: RecordType.idea, predicate: predicate, in: database)
        return result.map { records in records.compactMap(Idea.init) }
    }

    func createIdea(_ idea: Idea, in groupIdentifier: String) async -> Result<Idea, SparkError> {
        let zoneID = manager.zoneID(for: groupIdentifier)
        let database = manager.databaseForZone(zoneID)
        let record = idea.toRecord(in: zoneID)

        let result = await manager.save(record, in: database)
        return result.flatMap { saved in
            guard let idea = Idea(record: saved) else { return .failure(.unknown("Failed to parse saved idea")) }
            return .success(idea)
        }
    }

    func deleteIdea(_ idea: Idea) async -> Result<Void, SparkError> {
        let zoneID = manager.zoneID(for: idea.groupIdentifier)
        let database = manager.databaseForZone(zoneID)
        let recordID = CKRecord.ID(recordName: idea.id, zoneID: zoneID)

        // Delete associated votes first
        let votePredicate = NSPredicate(format: "ideaIdentifier == %@", idea.id)
        let votesResult = await manager.fetch(recordType: RecordType.vote, predicate: votePredicate, in: database)
        if case .success(let voteRecords) = votesResult {
            for voteRecord in voteRecords {
                _ = await manager.delete(voteRecord.recordID, in: database)
            }
        }

        return await manager.delete(recordID, in: database)
    }

    // MARK: - Votes

    func castVote(_ vote: Vote, on idea: Idea) async -> Result<Vote, SparkError> {
        let zoneID = manager.zoneID(for: idea.groupIdentifier)
        let database = manager.databaseForZone(zoneID)

        // Remove existing vote from same user on same idea
        let predicate = NSPredicate(format: "ideaIdentifier == %@ AND userIdentifier == %@", vote.ideaIdentifier, vote.userIdentifier)
        let existingResult = await manager.fetch(recordType: RecordType.vote, predicate: predicate, in: database)
        if case .success(let existing) = existingResult {
            for record in existing {
                _ = await manager.delete(record.recordID, in: database)
            }
        }

        let record = vote.toRecord(in: zoneID)
        let result = await manager.save(record, in: database)
        return result.flatMap { saved in
            guard let vote = Vote(record: saved) else { return .failure(.unknown("Failed to parse saved vote")) }
            return .success(vote)
        }
    }

    func removeVote(_ vote: Vote) async -> Result<Void, SparkError> {
        // We need to find the zone — votes reference an idea, which references a group
        // For simplicity, search across all zones
        let zones = await manager.fetchAllZones()
        if case .success(let allZones) = zones {
            for zone in allZones {
                let database = manager.databaseForZone(zone.zoneID)
                let recordID = CKRecord.ID(recordName: vote.id, zoneID: zone.zoneID)
                let result = await manager.delete(recordID, in: database)
                if case .success = result { return .success(()) }
            }
        }
        return .failure(.recordNotFound)
    }

    func votesForIdea(_ ideaIdentifier: String) async -> [Vote] {
        // Fan-out across zones
        let zones = await manager.fetchAllZones()
        guard case .success(let allZones) = zones else { return [] }

        var allVotes: [Vote] = []
        let predicate = NSPredicate(format: "ideaIdentifier == %@", ideaIdentifier)

        for zone in allZones {
            let database = manager.databaseForZone(zone.zoneID)
            let result = await manager.fetch(recordType: RecordType.vote, predicate: predicate, in: database)
            if case .success(let records) = result {
                allVotes.append(contentsOf: records.compactMap(Vote.init))
            }
        }
        return allVotes
    }

    // MARK: - Planned Dates

    func fetchUpcomingDates(for groupIdentifier: String) async -> Result<[PlannedDate], SparkError> {
        let zoneID = manager.zoneID(for: groupIdentifier)
        let database = manager.databaseForZone(zoneID)
        let predicate = NSPredicate(format: "groupIdentifier == %@ AND status == %@ AND date >= %@",
                                    groupIdentifier, DateStatus.planned.rawValue, NSDate())

        let result = await manager.fetch(
            recordType: RecordType.plannedDate,
            predicate: predicate,
            sortDescriptors: [NSSortDescriptor(key: "date", ascending: true)],
            in: database
        )
        return result.map { records in records.compactMap(PlannedDate.init) }
    }

    func fetchPastDates(for groupIdentifier: String) async -> Result<[PlannedDate], SparkError> {
        let zoneID = manager.zoneID(for: groupIdentifier)
        let database = manager.databaseForZone(zoneID)

        // Past dates: completed OR date in the past
        let completedPredicate = NSPredicate(format: "groupIdentifier == %@ AND status == %@",
                                             groupIdentifier, DateStatus.completed.rawValue)
        let pastPredicate = NSPredicate(format: "groupIdentifier == %@ AND date < %@",
                                        groupIdentifier, NSDate())
        let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [completedPredicate, pastPredicate])

        let result = await manager.fetch(
            recordType: RecordType.plannedDate,
            predicate: predicate,
            sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)],
            in: database
        )
        return result.map { records in records.compactMap(PlannedDate.init) }
    }

    func createPlannedDate(_ plannedDate: PlannedDate, in groupIdentifier: String) async -> Result<PlannedDate, SparkError> {
        let zoneID = manager.zoneID(for: groupIdentifier)
        let database = manager.databaseForZone(zoneID)
        let record = plannedDate.toRecord(in: zoneID)

        let result = await manager.save(record, in: database)
        return result.flatMap { saved in
            guard let date = PlannedDate(record: saved) else { return .failure(.unknown("Failed to parse saved date")) }
            return .success(date)
        }
    }

    func updatePlannedDate(_ plannedDate: PlannedDate) async -> Result<PlannedDate, SparkError> {
        let zoneID = manager.zoneID(for: plannedDate.groupIdentifier)
        let database = manager.databaseForZone(zoneID)
        let record = plannedDate.toRecord(in: zoneID)

        let result = await manager.save(record, in: database)
        return result.flatMap { saved in
            guard let date = PlannedDate(record: saved) else { return .failure(.unknown("Failed to parse saved date")) }
            return .success(date)
        }
    }

    func deletePlannedDate(_ plannedDate: PlannedDate) async -> Result<Void, SparkError> {
        let zoneID = manager.zoneID(for: plannedDate.groupIdentifier)
        let database = manager.databaseForZone(zoneID)
        let recordID = CKRecord.ID(recordName: plannedDate.id, zoneID: zoneID)
        return await manager.delete(recordID, in: database)
    }

    // MARK: - Itinerary Steps

    func fetchItinerarySteps(for plannedDate: PlannedDate) async -> Result<[ItineraryStep], SparkError> {
        let zoneID = manager.zoneID(for: plannedDate.groupIdentifier)
        let database = manager.databaseForZone(zoneID)
        let predicate = NSPredicate(format: "plannedDateIdentifier == %@", plannedDate.id)

        let result = await manager.fetch(
            recordType: RecordType.itineraryStep,
            predicate: predicate,
            sortDescriptors: [NSSortDescriptor(key: "order", ascending: true)],
            in: database
        )
        return result.map { records in records.compactMap(ItineraryStep.init) }
    }

    func createItineraryStep(_ step: ItineraryStep, for plannedDate: PlannedDate) async -> Result<ItineraryStep, SparkError> {
        let zoneID = manager.zoneID(for: plannedDate.groupIdentifier)
        let database = manager.databaseForZone(zoneID)
        let record = step.toRecord(in: zoneID)

        let result = await manager.save(record, in: database)
        return result.flatMap { saved in
            guard let step = ItineraryStep(record: saved) else { return .failure(.unknown("Failed to parse saved step")) }
            return .success(step)
        }
    }

    func updateItineraryStep(_ step: ItineraryStep) async -> Result<ItineraryStep, SparkError> {
        // Need the group identifier — fetch via planned date zone search
        let zones = await manager.fetchAllZones()
        guard case .success(let allZones) = zones else { return .failure(.networkUnavailable) }

        for zone in allZones {
            let database = manager.databaseForZone(zone.zoneID)
            let record = step.toRecord(in: zone.zoneID)
            let result = await manager.save(record, in: database)
            if case .success(let saved) = result {
                if let updatedStep = ItineraryStep(record: saved) {
                    return .success(updatedStep)
                }
            }
        }
        return .failure(.recordNotFound)
    }

    func deleteItineraryStep(_ step: ItineraryStep) async -> Result<Void, SparkError> {
        let zones = await manager.fetchAllZones()
        guard case .success(let allZones) = zones else { return .failure(.networkUnavailable) }

        for zone in allZones {
            let database = manager.databaseForZone(zone.zoneID)
            let recordID = CKRecord.ID(recordName: step.id, zoneID: zone.zoneID)
            let result = await manager.delete(recordID, in: database)
            if case .success = result { return .success(()) }
        }
        return .failure(.recordNotFound)
    }

    // MARK: - Journal Entries

    func fetchJournalEntry(for plannedDate: PlannedDate) async -> Result<JournalEntry?, SparkError> {
        let zoneID = manager.zoneID(for: plannedDate.groupIdentifier)
        let database = manager.databaseForZone(zoneID)
        let predicate = NSPredicate(format: "plannedDateIdentifier == %@", plannedDate.id)

        let result = await manager.fetch(recordType: RecordType.journalEntry, predicate: predicate, in: database)
        return result.map { records in records.compactMap(JournalEntry.init).first }
    }

    func createJournalEntry(_ entry: JournalEntry, for plannedDate: PlannedDate) async -> Result<JournalEntry, SparkError> {
        let zoneID = manager.zoneID(for: plannedDate.groupIdentifier)
        let database = manager.databaseForZone(zoneID)
        let record = entry.toRecord(in: zoneID)

        let result = await manager.save(record, in: database)
        return result.flatMap { saved in
            guard let entry = JournalEntry(record: saved) else { return .failure(.unknown("Failed to parse saved entry")) }
            return .success(entry)
        }
    }

    func updateJournalEntry(_ entry: JournalEntry) async -> Result<JournalEntry, SparkError> {
        let zones = await manager.fetchAllZones()
        guard case .success(let allZones) = zones else { return .failure(.networkUnavailable) }

        for zone in allZones {
            let database = manager.databaseForZone(zone.zoneID)
            let record = entry.toRecord(in: zone.zoneID)
            let result = await manager.save(record, in: database)
            if case .success(let saved) = result {
                if let updatedEntry = JournalEntry(record: saved) {
                    return .success(updatedEntry)
                }
            }
        }
        return .failure(.recordNotFound)
    }
}
