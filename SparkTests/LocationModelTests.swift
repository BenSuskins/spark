import Testing
@testable import Spark

@Test @MainActor func requestLocationAuthorizationGranted() async {
    let service = FakeLocationService()
    let model = LocationModel(locationService: service)

    await model.requestAuthorization()

    #expect(model.isAuthorized == true)
}

@Test @MainActor func requestLocationAuthorizationDenied() async {
    let service = FakeLocationService()
    service.authorizationGranted = false
    let model = LocationModel(locationService: service)

    await model.requestAuthorization()

    #expect(model.isAuthorized == false)
}
