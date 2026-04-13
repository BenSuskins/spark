import Foundation
import CloudKit

final class CloudKitManager: @unchecked Sendable {
    static let containerIdentifier = "iCloud.uk.co.suskins.Spark"

    let container: CKContainer
    let privateDatabase: CKDatabase

    init() {
        container = CKContainer(identifier: Self.containerIdentifier)
        privateDatabase = container.privateCloudDatabase
    }

    func currentUserIdentifier() async -> Result<String, SparkError> {
        do {
            let recordID = try await container.userRecordID()
            return .success(recordID.recordName)
        } catch {
            return .failure(.notAuthenticated)
        }
    }

    func save(_ record: CKRecord, in database: CKDatabase) async -> Result<CKRecord, SparkError> {
        do {
            let saved = try await database.save(record)
            return .success(saved)
        } catch let error as CKError {
            return .failure(mapError(error))
        } catch {
            return .failure(.cloudKitError(error.localizedDescription))
        }
    }

    func delete(_ recordID: CKRecord.ID, in database: CKDatabase) async -> Result<Void, SparkError> {
        do {
            _ = try await database.deleteRecord(withID: recordID)
            return .success(())
        } catch let error as CKError {
            return .failure(mapError(error))
        } catch {
            return .failure(.cloudKitError(error.localizedDescription))
        }
    }

    func fetch(
        recordType: String,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]? = nil,
        zoneID: CKRecordZone.ID? = nil,
        in database: CKDatabase
    ) async -> Result<[CKRecord], SparkError> {
        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = sortDescriptors

        do {
            let matchResults: [(CKRecord.ID, Result<CKRecord, Error>)]
            if let zoneID {
                (matchResults, _) = try await database.records(matching: query, inZoneWith: zoneID)
            } else {
                (matchResults, _) = try await database.records(matching: query)
            }
            let records = matchResults.compactMap { try? $0.1.get() }
            return .success(records)
        } catch let error as CKError {
            return .failure(mapError(error))
        } catch {
            return .failure(.cloudKitError(error.localizedDescription))
        }
    }

    func zoneID(for groupIdentifier: String) -> CKRecordZone.ID {
        CKRecordZone.ID(zoneName: "group-\(groupIdentifier)", ownerName: CKCurrentUserDefaultName)
    }

    func createZone(_ zoneID: CKRecordZone.ID) async -> Result<CKRecordZone, SparkError> {
        let zone = CKRecordZone(zoneID: zoneID)
        do {
            let saved = try await privateDatabase.save(zone)
            return .success(saved)
        } catch let error as CKError {
            return .failure(mapError(error))
        } catch {
            return .failure(.cloudKitError(error.localizedDescription))
        }
    }

    func fetchAllZones() async -> Result<[CKRecordZone], SparkError> {
        do {
            let zones = try await privateDatabase.allRecordZones()
            return .success(zones)
        } catch let error as CKError {
            return .failure(mapError(error))
        } catch {
            return .failure(.cloudKitError(error.localizedDescription))
        }
    }

    func databaseForZone(_ zoneID: CKRecordZone.ID) -> CKDatabase {
        if zoneID.ownerName == CKCurrentUserDefaultName {
            return privateDatabase
        }
        return container.sharedCloudDatabase
    }

    private func mapError(_ error: CKError) -> SparkError {
        switch error.code {
        case .networkUnavailable, .networkFailure:
            return .networkUnavailable
        case .notAuthenticated:
            return .notAuthenticated
        case .unknownItem:
            return .recordNotFound
        case .permissionFailure:
            return .permissionDenied
        default:
            return .cloudKitError(error.localizedDescription)
        }
    }
}
