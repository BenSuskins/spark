import Foundation
import Observation

@MainActor
@Observable
final class LocationModel {
    private(set) var isAuthorized = false
    private(set) var error: SparkError?

    private let locationService: LocationService

    init(locationService: LocationService) {
        self.locationService = locationService
    }

    func requestAuthorization() async {
        let result = await locationService.requestWhenInUseAuthorization()

        switch result {
        case .success(let granted):
            isAuthorized = granted
        case .failure(let authError):
            error = authError
            isAuthorized = false
        }
    }
}
