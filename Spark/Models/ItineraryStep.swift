import Foundation
import CoreLocation

struct ItineraryStep: Identifiable, Sendable, Equatable {
    let id: String
    let plannedDateIdentifier: String
    let venueName: String
    let venueCoordinate: CLLocationCoordinate2D?
    let time: Date
    let notes: String
    let order: Int

    static func == (lhs: ItineraryStep, rhs: ItineraryStep) -> Bool {
        lhs.id == rhs.id
            && lhs.plannedDateIdentifier == rhs.plannedDateIdentifier
            && lhs.venueName == rhs.venueName
            && lhs.time == rhs.time
            && lhs.notes == rhs.notes
            && lhs.order == rhs.order
    }
}
