import Foundation
import CloudKit
import CoreLocation

// MARK: - Record Type Constants

enum RecordType {
    static let group = "Group"
    static let idea = "Idea"
    static let vote = "Vote"
    static let plannedDate = "PlannedDate"
    static let itineraryStep = "ItineraryStep"
    static let journalEntry = "JournalEntry"
}

// MARK: - Group

extension Group {
    init?(record: CKRecord) {
        guard record.recordType == RecordType.group,
              let name = record["name"] as? String,
              let createdDate = record["createdDate"] as? Date,
              let ownerIdentifier = record["ownerIdentifier"] as? String
        else { return nil }

        let emoji = (record["emoji"] as? String) ?? "💞"

        self.init(
            id: record.recordID.recordName,
            name: name,
            emoji: emoji,
            createdDate: createdDate,
            ownerIdentifier: ownerIdentifier
        )
    }

    func toRecord(in zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
        let record = CKRecord(recordType: RecordType.group, recordID: recordID)
        record["name"] = name
        record["emoji"] = emoji
        record["createdDate"] = createdDate
        record["ownerIdentifier"] = ownerIdentifier
        return record
    }
}

// MARK: - Idea

extension Idea {
    init?(record: CKRecord) {
        guard record.recordType == RecordType.idea,
              let title = record["title"] as? String,
              let categoryRaw = record["category"] as? String,
              let category = IdeaCategory(rawValue: categoryRaw),
              let createdBy = record["createdBy"] as? String,
              let createdDate = record["createdDate"] as? Date,
              let groupIdentifier = record["groupIdentifier"] as? String
        else { return nil }

        let isPlanned = record["isPlanned"] as? Bool ?? false

        self.init(
            id: record.recordID.recordName,
            title: title,
            category: category,
            createdBy: createdBy,
            createdDate: createdDate,
            groupIdentifier: groupIdentifier,
            isPlanned: isPlanned
        )
    }

    func toRecord(in zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
        let record = CKRecord(recordType: RecordType.idea, recordID: recordID)
        record["title"] = title
        record["category"] = category.rawValue
        record["createdBy"] = createdBy
        record["createdDate"] = createdDate
        record["groupIdentifier"] = groupIdentifier
        record["isPlanned"] = isPlanned
        return record
    }
}

// MARK: - Vote

extension Vote {
    init?(record: CKRecord) {
        guard record.recordType == RecordType.vote,
              let ideaIdentifier = record["ideaIdentifier"] as? String,
              let userIdentifier = record["userIdentifier"] as? String,
              let value = record["value"] as? Int
        else { return nil }

        self.init(
            id: record.recordID.recordName,
            ideaIdentifier: ideaIdentifier,
            userIdentifier: userIdentifier,
            value: value
        )
    }

    func toRecord(in zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
        let record = CKRecord(recordType: RecordType.vote, recordID: recordID)
        record["ideaIdentifier"] = ideaIdentifier
        record["userIdentifier"] = userIdentifier
        record["value"] = value
        return record
    }
}

// MARK: - PlannedDate

extension PlannedDate {
    init?(record: CKRecord) {
        guard record.recordType == RecordType.plannedDate,
              let title = record["title"] as? String,
              let date = record["date"] as? Date,
              let statusRaw = record["status"] as? String,
              let status = DateStatus(rawValue: statusRaw),
              let groupIdentifier = record["groupIdentifier"] as? String
        else { return nil }

        self.init(
            id: record.recordID.recordName,
            title: title,
            date: date,
            status: status,
            groupIdentifier: groupIdentifier
        )
    }

    func toRecord(in zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
        let record = CKRecord(recordType: RecordType.plannedDate, recordID: recordID)
        record["title"] = title
        record["date"] = date
        record["status"] = status.rawValue
        record["groupIdentifier"] = groupIdentifier
        return record
    }
}

// MARK: - ItineraryStep

extension ItineraryStep {
    init?(record: CKRecord) {
        guard record.recordType == RecordType.itineraryStep,
              let plannedDateIdentifier = record["plannedDateIdentifier"] as? String,
              let venueName = record["venueName"] as? String,
              let time = record["time"] as? Date,
              let notes = record["notes"] as? String,
              let order = record["order"] as? Int
        else { return nil }

        let coordinate: CLLocationCoordinate2D?
        if let location = record["venueLocation"] as? CLLocation {
            coordinate = location.coordinate
        } else {
            coordinate = nil
        }

        self.init(
            id: record.recordID.recordName,
            plannedDateIdentifier: plannedDateIdentifier,
            venueName: venueName,
            venueCoordinate: coordinate,
            time: time,
            notes: notes,
            order: order
        )
    }

    func toRecord(in zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
        let record = CKRecord(recordType: RecordType.itineraryStep, recordID: recordID)
        record["plannedDateIdentifier"] = plannedDateIdentifier
        record["venueName"] = venueName
        record["time"] = time
        record["notes"] = notes
        record["order"] = order
        if let venueCoordinate {
            record["venueLocation"] = CLLocation(latitude: venueCoordinate.latitude, longitude: venueCoordinate.longitude)
        }
        return record
    }
}

// MARK: - JournalEntry

extension JournalEntry {
    init?(record: CKRecord) {
        guard record.recordType == RecordType.journalEntry,
              let plannedDateIdentifier = record["plannedDateIdentifier"] as? String,
              let rating = record["rating"] as? Int,
              let notes = record["notes"] as? String,
              let createdDate = record["createdDate"] as? Date
        else { return nil }

        self.init(
            id: record.recordID.recordName,
            plannedDateIdentifier: plannedDateIdentifier,
            rating: rating,
            notes: notes,
            createdDate: createdDate
        )
    }

    func toRecord(in zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
        let record = CKRecord(recordType: RecordType.journalEntry, recordID: recordID)
        record["plannedDateIdentifier"] = plannedDateIdentifier
        record["rating"] = rating
        record["notes"] = notes
        record["createdDate"] = createdDate
        return record
    }
}
