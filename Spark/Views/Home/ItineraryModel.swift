import Foundation
import CoreLocation
import Observation

@MainActor
@Observable
final class ItineraryModel {
    private(set) var steps: [ItineraryStep] = []
    private(set) var isLoading = false
    private(set) var error: SparkError?

    let plannedDate: PlannedDate
    private let repository: DateRepository

    init(repository: DateRepository, plannedDate: PlannedDate) {
        self.repository = repository
        self.plannedDate = plannedDate
    }

    func loadSteps() async {
        isLoading = true
        let result = await repository.fetchItinerarySteps(for: plannedDate)

        if case .success(let loadedSteps) = result {
            steps = loadedSteps
        } else if case .failure(let sparkError) = result {
            error = sparkError
        }

        isLoading = false
    }

    func addStep(venueName: String, venueCoordinate: CLLocationCoordinate2D?, time: Date, notes: String) async {
        error = nil
        let step = ItineraryStep(
            id: UUID().uuidString,
            plannedDateIdentifier: plannedDate.id,
            venueName: venueName,
            venueCoordinate: venueCoordinate,
            time: time,
            notes: notes,
            order: steps.count + 1
        )

        let result = await repository.createItineraryStep(step, for: plannedDate)

        switch result {
        case .success:
            await loadSteps()
        case .failure(let stepError):
            error = stepError
        }
    }

    func deleteStep(_ step: ItineraryStep) async {
        error = nil
        let result = await repository.deleteItineraryStep(step)

        switch result {
        case .success:
            await loadSteps()
        case .failure(let stepError):
            error = stepError
        }
    }
}
