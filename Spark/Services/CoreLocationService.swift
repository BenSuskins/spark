import Foundation
import CoreLocation

final class CoreLocationService: NSObject, LocationService, CLLocationManagerDelegate, @unchecked Sendable {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<Result<Bool, SparkError>, Never>?

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestWhenInUseAuthorization() async -> Result<Bool, SparkError> {
        let status = manager.authorizationStatus

        if status == .authorizedWhenInUse || status == .authorizedAlways {
            return .success(true)
        }

        if status == .denied || status == .restricted {
            return .success(false)
        }

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        guard status != .notDetermined else { return }

        let granted = status == .authorizedWhenInUse || status == .authorizedAlways
        continuation?.resume(returning: .success(granted))
        continuation = nil
    }
}
