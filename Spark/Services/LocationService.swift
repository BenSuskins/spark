import Foundation

protocol LocationService: Sendable {
    func requestWhenInUseAuthorization() async -> Result<Bool, SparkError>
}
