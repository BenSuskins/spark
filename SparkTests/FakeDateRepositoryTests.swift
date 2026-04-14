import Testing
@testable import Spark

@Test func createIdeaAddsToRepository() async {
    let repository = FakeDateRepository()
    let idea = Idea(
        id: "idea-1",
        title: "Sushi dinner",
        category: .dining,
        createdBy: "user-1",
        createdDate: .now,
        groupIdentifier: "group-1"
    )

    let result = await repository.createIdea(idea, in: "group-1")

    switch result {
    case .success(let created):
        #expect(created.title == "Sushi dinner")
        #expect(created.category == .dining)
    case .failure:
        Issue.record("Expected success")
    }
}

@Test func fetchIdeasReturnsOnlyForGroup() async {
    let repository = FakeDateRepository()
    let idea1 = Idea(id: "1", title: "Hiking", category: .outdoors, createdBy: "u1", createdDate: .now, groupIdentifier: "group-1")
    let idea2 = Idea(id: "2", title: "Movie", category: .entertainment, createdBy: "u1", createdDate: .now, groupIdentifier: "group-2")

    _ = await repository.createIdea(idea1, in: "group-1")
    _ = await repository.createIdea(idea2, in: "group-2")

    let result = await repository.fetchIdeas(for: "group-1")

    switch result {
    case .success(let ideas):
        #expect(ideas.count == 1)
        #expect(ideas.first?.title == "Hiking")
    case .failure:
        Issue.record("Expected success")
    }
}

@Test func deleteIdeaRemovesFromRepository() async {
    let repository = FakeDateRepository()
    let idea = Idea(id: "1", title: "Hiking", category: .outdoors, createdBy: "u1", createdDate: .now, groupIdentifier: "group-1")

    _ = await repository.createIdea(idea, in: "group-1")
    _ = await repository.deleteIdea(idea)

    let result = await repository.fetchIdeas(for: "group-1")

    switch result {
    case .success(let ideas):
        #expect(ideas.isEmpty)
    case .failure:
        Issue.record("Expected success")
    }
}

@Test func castVoteAddsVoteToIdea() async {
    let repository = FakeDateRepository()
    let idea = Idea(id: "idea-1", title: "Beach", category: .outdoors, createdBy: "u1", createdDate: .now, groupIdentifier: "group-1")
    _ = await repository.createIdea(idea, in: "group-1")

    let vote = Vote(id: "vote-1", ideaIdentifier: "idea-1", userIdentifier: "u1", value: 1)
    let result = await repository.castVote(vote, on: idea)

    switch result {
    case .success(let created):
        #expect(created.value == 1)
    case .failure:
        Issue.record("Expected success")
    }
}

@Test func removeVoteDeletesVote() async {
    let repository = FakeDateRepository()
    let idea = Idea(id: "idea-1", title: "Beach", category: .outdoors, createdBy: "u1", createdDate: .now, groupIdentifier: "group-1")
    _ = await repository.createIdea(idea, in: "group-1")

    let vote = Vote(id: "vote-1", ideaIdentifier: "idea-1", userIdentifier: "u1", value: 1)
    _ = await repository.castVote(vote, on: idea)
    _ = await repository.removeVote(vote, in: "group-1")

    let votes = await repository.votesForIdea("idea-1")
    #expect(votes.isEmpty)
}

@Test func voteTallyCalculatesCorrectScore() async {
    let repository = FakeDateRepository()
    let idea = Idea(id: "idea-1", title: "Beach", category: .outdoors, createdBy: "u1", createdDate: .now, groupIdentifier: "group-1")
    _ = await repository.createIdea(idea, in: "group-1")

    let upvote1 = Vote(id: "v1", ideaIdentifier: "idea-1", userIdentifier: "u1", value: 1)
    let upvote2 = Vote(id: "v2", ideaIdentifier: "idea-1", userIdentifier: "u2", value: 1)
    let downvote = Vote(id: "v3", ideaIdentifier: "idea-1", userIdentifier: "u3", value: -1)

    _ = await repository.castVote(upvote1, on: idea)
    _ = await repository.castVote(upvote2, on: idea)
    _ = await repository.castVote(downvote, on: idea)

    let votes = await repository.votesForIdea("idea-1")
    let tally = votes.reduce(0) { $0 + $1.value }
    #expect(tally == 1)
    #expect(votes.count == 3)
}

@Test func castVoteReplacesExistingVoteFromSameUser() async {
    let repository = FakeDateRepository()
    let idea = Idea(id: "idea-1", title: "Beach", category: .outdoors, createdBy: "u1", createdDate: .now, groupIdentifier: "group-1")
    _ = await repository.createIdea(idea, in: "group-1")

    let upvote = Vote(id: "v1", ideaIdentifier: "idea-1", userIdentifier: "u1", value: 1)
    _ = await repository.castVote(upvote, on: idea)

    let downvote = Vote(id: "v2", ideaIdentifier: "idea-1", userIdentifier: "u1", value: -1)
    _ = await repository.castVote(downvote, on: idea)

    let votes = await repository.votesForIdea("idea-1")
    #expect(votes.count == 1)
    #expect(votes.first?.value == -1)
}
