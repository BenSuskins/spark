import Foundation

final class FakeLocationService: LocationService, @unchecked Sendable {
    var authorizationGranted = true

    func requestWhenInUseAuthorization() async -> Result<Bool, SparkError> {
        .success(authorizationGranted)
    }
}
