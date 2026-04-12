import Testing
@testable import Spark

@Test @MainActor func loadIdeasGroupsByCategory() async {
    let repository = FakeDateRepository()
    let dining = Idea(id: "1", title: "Sushi", category: .dining, createdBy: "u1", createdDate: .now, groupIdentifier: "g1")
    let outdoor = Idea(id: "2", title: "Hiking", category: .outdoors, createdBy: "u1", createdDate: .now, groupIdentifier: "g1")
    _ = await repository.createIdea(dining, in: "g1")
    _ = await repository.createIdea(outdoor, in: "g1")

    let model = IdeasModel(repository: repository, groupIdentifier: "g1", currentUserIdentifier: "u1")
    await model.loadIdeas()

    #expect(model.ideasByCategory[.dining]?.count == 1)
    #expect(model.ideasByCategory[.outdoors]?.count == 1)
    #expect(model.ideasByCategory[.entertainment]?.isEmpty == true)
}

@Test @MainActor func addIdeaAppearsAfterLoad() async {
    let repository = FakeDateRepository()
    let model = IdeasModel(repository: repository, groupIdentifier: "g1", currentUserIdentifier: "u1")

    await model.addIdea(title: "Bowling", category: .entertainment)

    #expect(model.ideasByCategory[.entertainment]?.count == 1)
    #expect(model.ideasByCategory[.entertainment]?.first?.title == "Bowling")
}

@Test @MainActor func toggleVoteUpvoteThenRemove() async {
    let repository = FakeDateRepository()
    let idea = Idea(id: "idea-1", title: "Beach", category: .outdoors, createdBy: "u1", createdDate: .now, groupIdentifier: "g1")
    _ = await repository.createIdea(idea, in: "g1")

    let model = IdeasModel(repository: repository, groupIdentifier: "g1", currentUserIdentifier: "u1")
    await model.loadIdeas()

    await model.toggleVote(on: idea, value: 1)
    #expect(model.score(for: "idea-1") == 1)
    #expect(model.currentUserVote(for: "idea-1") == 1)

    await model.toggleVote(on: idea, value: 1)
    #expect(model.score(for: "idea-1") == 0)
    #expect(model.currentUserVote(for: "idea-1") == nil)
}

@Test @MainActor func toggleVoteSwitchesFromUpToDown() async {
    let repository = FakeDateRepository()
    let idea = Idea(id: "idea-1", title: "Beach", category: .outdoors, createdBy: "u1", createdDate: .now, groupIdentifier: "g1")
    _ = await repository.createIdea(idea, in: "g1")

    let model = IdeasModel(repository: repository, groupIdentifier: "g1", currentUserIdentifier: "u1")
    await model.loadIdeas()

    await model.toggleVote(on: idea, value: 1)
    #expect(model.currentUserVote(for: "idea-1") == 1)

    await model.toggleVote(on: idea, value: -1)
    #expect(model.currentUserVote(for: "idea-1") == -1)
    #expect(model.score(for: "idea-1") == -1)
}

@Test @MainActor func sortedIdeasOrdersByScore() async {
    let repository = FakeDateRepository()
    let low = Idea(id: "1", title: "Low", category: .dining, createdBy: "u1", createdDate: .now, groupIdentifier: "g1")
    let high = Idea(id: "2", title: "High", category: .dining, createdBy: "u1", createdDate: .now, groupIdentifier: "g1")
    _ = await repository.createIdea(low, in: "g1")
    _ = await repository.createIdea(high, in: "g1")

    let vote1 = Vote(id: "v1", ideaIdentifier: "2", userIdentifier: "u1", value: 1)
    let vote2 = Vote(id: "v2", ideaIdentifier: "2", userIdentifier: "u2", value: 1)
    let vote3 = Vote(id: "v3", ideaIdentifier: "1", userIdentifier: "u1", value: -1)
    _ = await repository.castVote(vote1, on: high)
    _ = await repository.castVote(vote2, on: high)
    _ = await repository.castVote(vote3, on: low)

    let model = IdeasModel(repository: repository, groupIdentifier: "g1", currentUserIdentifier: "u1")
    await model.loadIdeas()

    let sorted = model.sortedIdeas(for: .dining)
    #expect(sorted.first?.title == "High")
    #expect(sorted.last?.title == "Low")
}

@Test @MainActor func deleteIdeaRemovesFromModel() async {
    let repository = FakeDateRepository()
    let model = IdeasModel(repository: repository, groupIdentifier: "g1", currentUserIdentifier: "u1")

    await model.addIdea(title: "Remove me", category: .adventure)
    let idea = model.ideasByCategory[.adventure]!.first!

    await model.deleteIdea(idea)

    #expect(model.ideasByCategory[.adventure]?.isEmpty == true)
}
