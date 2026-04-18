import Foundation
import CloudKit

final class CloudKitGroupRepository: GroupRepository, @unchecked Sendable {
    private let manager: CloudKitManager

    init(manager: CloudKitManager = CloudKitManager()) {
        self.manager = manager
    }

    func fetchGroups() async -> Result<[Group], SparkError> {
        let zonesResult = await manager.fetchAllZones()

        switch zonesResult {
        case .success(let zones):
            let groupZones = zones.filter { $0.zoneID.zoneName.hasPrefix("group-") }
            var groups: [Group] = []

            for zone in groupZones {
                let database = manager.databaseForZone(zone.zoneID)
                let predicate = NSPredicate(value: true)
                let result = await manager.fetch(recordType: RecordType.group, predicate: predicate, in: database)
                if case .success(let records) = result {
                    groups.append(contentsOf: records.compactMap(Group.init))
                }
            }

            return .success(groups)
        case .failure(let error):
            return .failure(error)
        }
    }

    func createGroup(name: String, emoji: String) async -> Result<Group, SparkError> {
        let userResult = await manager.currentUserIdentifier()
        guard case .success(let userIdentifier) = userResult else {
            return .failure(.notAuthenticated)
        }

        let groupId = UUID().uuidString
        let zoneID = manager.zoneID(for: groupId)

        let zoneResult = await manager.createZone(zoneID)
        guard case .success = zoneResult else {
            if case .failure(let error) = zoneResult { return .failure(error) }
            return .failure(.unknown("Failed to create zone"))
        }

        let group = Group(
            id: groupId,
            name: name,
            emoji: emoji,
            createdDate: .now,
            ownerIdentifier: userIdentifier
        )

        let record = group.toRecord(in: zoneID)
        let result = await manager.save(record, in: manager.privateDatabase)

        return result.flatMap { saved in
            guard let group = Group(record: saved) else { return .failure(.unknown("Failed to parse saved group")) }
            return .success(group)
        }
    }

    func updateGroup(_ group: Group) async -> Result<Group, SparkError> {
        let zoneID = manager.zoneID(for: group.id)
        let recordID = CKRecord.ID(recordName: group.id, zoneID: zoneID)

        do {
            let record = try await manager.privateDatabase.record(for: recordID)
            record["name"] = group.name as CKRecordValue
            record["emoji"] = group.emoji as CKRecordValue

            let result = try await manager.privateDatabase.modifyRecords(saving: [record], deleting: [])
            let saved = result.saveResults.values.compactMap { try? $0.get() }.first
            guard let savedRecord = saved, let updated = Group(record: savedRecord) else {
                return .failure(.unknown("Failed to parse updated group"))
            }
            return .success(updated)
        } catch {
            return .failure(.cloudKitError(error.localizedDescription))
        }
    }

    func deleteGroup(_ group: Group) async -> Result<Void, SparkError> {
        let zoneID = manager.zoneID(for: group.id)
        // Deleting the zone removes all records within it
        do {
            _ = try await manager.privateDatabase.deleteRecordZone(withID: zoneID)
            return .success(())
        } catch {
            return .failure(.cloudKitError(error.localizedDescription))
        }
    }

    func shareGroup(_ group: Group) async -> Result<URL, SparkError> {
        let zoneID = manager.zoneID(for: group.id)
        let recordID = CKRecord.ID(recordName: group.id, zoneID: zoneID)

        do {
            let rootRecord = try await manager.privateDatabase.record(for: recordID)
            let share = CKShare(rootRecord: rootRecord)
            share[CKShare.SystemFieldKey.title] = group.name
            share.publicPermission = .readWrite

            let result = try await manager.privateDatabase.modifyRecords(saving: [rootRecord, share], deleting: [])
            let savedShare = result.saveResults.values.compactMap { try? $0.get() as? CKShare }.first
            if let url = savedShare?.url {
                return .success(url)
            }
            return .failure(.unknown("Failed to create share URL"))
        } catch {
            return .failure(.cloudKitError(error.localizedDescription))
        }
    }

    func acceptShare(from url: URL) async -> Result<Group, SparkError> {
        do {
            let metadata = try await manager.container.shareMetadata(for: url)
            try await manager.container.accept(metadata)

            // Fetch the shared group record
            let sharedDatabase = manager.container.sharedCloudDatabase
            let predicate = NSPredicate(value: true)
            let result = await manager.fetch(recordType: RecordType.group, predicate: predicate, in: sharedDatabase)

            if case .success(let records) = result,
               let group = records.compactMap(Group.init).last {
                return .success(group)
            }

            return .failure(.recordNotFound)
        } catch {
            return .failure(.cloudKitError(error.localizedDescription))
        }
    }
}
