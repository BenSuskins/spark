import SwiftUI
import MapKit

struct ItineraryMapView: View {
    let steps: [ItineraryStep]

    var body: some View {
        Map {
            ForEach(steps) { step in
                if let coordinate = step.venueCoordinate {
                    Marker(step.venueName, coordinate: coordinate)
                }
            }
        }
    }
}
