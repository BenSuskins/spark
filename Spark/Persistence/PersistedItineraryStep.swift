import Foundation
import SwiftData
import CoreLocation

@Model
final class PersistedItineraryStep {
    var identifier: String
    var plannedDateIdentifier: String
    var venueName: String
    var venueLatitude: Double?
    var venueLongitude: Double?
    var time: Date
    var notes: String
    var order: Int
    var groupIdentifier: String
    var syncStatus: String

    init(identifier: String, plannedDateIdentifier: String, venueName: String, venueLatitude: Double?, venueLongitude: Double?, time: Date, notes: String, order: Int, groupIdentifier: String, syncStatus: SyncStatus = .synced) {
        self.identifier = identifier
        self.plannedDateIdentifier = plannedDateIdentifier
        self.venueName = venueName
        self.venueLatitude = venueLatitude
        self.venueLongitude = venueLongitude
        self.time = time
        self.notes = notes
        self.order = order
        self.groupIdentifier = groupIdentifier
        self.syncStatus = syncStatus.rawValue
    }

    convenience init(from step: ItineraryStep, groupIdentifier: String, syncStatus: SyncStatus = .synced) {
        self.init(
            identifier: step.id,
            plannedDateIdentifier: step.plannedDateIdentifier,
            venueName: step.venueName,
            venueLatitude: step.venueCoordinate?.latitude,
            venueLongitude: step.venueCoordinate?.longitude,
            time: step.time,
            notes: step.notes,
            order: step.order,
            groupIdentifier: groupIdentifier,
            syncStatus: syncStatus
        )
    }

    func toModel() -> ItineraryStep {
        let coordinate: CLLocationCoordinate2D?
        if let venueLatitude, let venueLongitude {
            coordinate = CLLocationCoordinate2D(latitude: venueLatitude, longitude: venueLongitude)
        } else {
            coordinate = nil
        }

        return ItineraryStep(
            id: identifier,
            plannedDateIdentifier: plannedDateIdentifier,
            venueName: venueName,
            venueCoordinate: coordinate,
            time: time,
            notes: notes,
            order: order
        )
    }

    func update(from step: ItineraryStep) {
        plannedDateIdentifier = step.plannedDateIdentifier
        venueName = step.venueName
        venueLatitude = step.venueCoordinate?.latitude
        venueLongitude = step.venueCoordinate?.longitude
        time = step.time
        notes = step.notes
        order = step.order
    }
}
