import Foundation
import Observation

@MainActor
@Observable
final class IdeasModel {
    private(set) var ideasByCategory: [IdeaCategory: [Idea]] = [:]
    private(set) var votesByIdea: [String: [Vote]] = [:]
    private(set) var isLoading = false
    private(set) var error: SparkError?

    private let repository: DateRepository
    private let currentUserIdentifier: String
    private(set) var groupIdentifier: String

    init(repository: DateRepository, groupIdentifier: String, currentUserIdentifier: String) {
        self.repository = repository
        self.groupIdentifier = groupIdentifier
        self.currentUserIdentifier = currentUserIdentifier
    }

    func updateGroup(_ groupIdentifier: String) {
        self.groupIdentifier = groupIdentifier
    }

    func loadIdeas() async {
        isLoading = true
        error = nil

        let result = await repository.fetchIdeas(for: groupIdentifier)

        switch result {
        case .success(let ideas):
            let unplannedIdeas = ideas.filter { !$0.isPlanned }
            var grouped: [IdeaCategory: [Idea]] = [:]
            for category in IdeaCategory.allCases {
                grouped[category] = unplannedIdeas.filter { $0.category == category }
            }
            ideasByCategory = grouped

            let votesResult = await repository.fetchAllVotes(for: groupIdentifier)
            if case .success(let allVotes) = votesResult {
                votesByIdea = allVotes
            }

        case .failure(let sparkError):
            error = sparkError
        }

        isLoading = false
    }

    func addIdea(title: String, category: IdeaCategory) async {
        error = nil
        let idea = Idea(
            id: UUID().uuidString,
            title: title,
            category: category,
            createdBy: currentUserIdentifier,
            createdDate: .now,
            groupIdentifier: groupIdentifier
        )

        let result = await repository.createIdea(idea, in: groupIdentifier)

        switch result {
        case .success:
            await loadIdeas()
        case .failure(let ideaError):
            error = ideaError
        }
    }

    func deleteIdea(_ idea: Idea) async {
        let result = await repository.deleteIdea(idea)

        if case .success = result {
            await loadIdeas()
        }
    }

    func toggleVote(on idea: Idea, value: Int) async {
        let existingVotes = votesByIdea[idea.id] ?? []
        let existingVote = existingVotes.first { $0.userIdentifier == currentUserIdentifier }

        if let existing = existingVote, existing.value == value {
            _ = await repository.removeVote(existing, in: groupIdentifier)
        } else {
            let vote = Vote(
                id: UUID().uuidString,
                ideaIdentifier: idea.id,
                userIdentifier: currentUserIdentifier,
                value: value
            )
            _ = await repository.castVote(vote, on: idea)
        }

        await loadIdeas()
    }

    func score(for ideaIdentifier: String) -> Int {
        (votesByIdea[ideaIdentifier] ?? []).reduce(0) { $0 + $1.value }
    }

    func currentUserVote(for ideaIdentifier: String) -> Int? {
        (votesByIdea[ideaIdentifier] ?? [])
            .first { $0.userIdentifier == currentUserIdentifier }?
            .value
    }

    func sortedIdeas(for category: IdeaCategory) -> [Idea] {
        (ideasByCategory[category] ?? []).sorted { score(for: $0.id) > score(for: $1.id) }
    }
}
