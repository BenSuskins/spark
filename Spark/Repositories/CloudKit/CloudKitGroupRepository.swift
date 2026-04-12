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

    func createGroup(name: String) async -> Result<Group, SparkError> {
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

        let share = CKShare(rootRecord: CKRecord(recordType: RecordType.group, recordID: recordID))
        share[CKShare.SystemFieldKey.title] = group.name
        share.publicPermission = .readWrite

        do {
            let saved = try await manager.privateDatabase.save(share)
            if let share = saved as? CKShare, let url = share.url {
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
