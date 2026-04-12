import Testing
@testable import Spark

@Test func ideaCategoryHasAllExpectedCases() {
    let categories = IdeaCategory.allCases
    #expect(categories.count == 6)
    #expect(categories.contains(.dining))
    #expect(categories.contains(.outdoors))
    #expect(categories.contains(.entertainment))
    #expect(categories.contains(.adventure))
    #expect(categories.contains(.stayIn))
    #expect(categories.contains(.travel))
}

@Test func ideaCategorySystemImages() {
    #expect(IdeaCategory.dining.systemImage == "fork.knife")
    #expect(IdeaCategory.outdoors.systemImage == "leaf")
    #expect(IdeaCategory.entertainment.systemImage == "film")
    #expect(IdeaCategory.adventure.systemImage == "figure.hiking")
    #expect(IdeaCategory.stayIn.systemImage == "house")
    #expect(IdeaCategory.travel.systemImage == "airplane")
}
