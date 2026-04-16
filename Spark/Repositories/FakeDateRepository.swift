import Foundation

final class FakeDateRepository: DateRepository, @unchecked Sendable {
    private var ideas: [Idea] = []
    private var votes: [Vote] = []
    private var plannedDates: [PlannedDate] = []
    private var itinerarySteps: [ItineraryStep] = []
    private var journalEntries: [JournalEntry] = []

    // MARK: - Ideas

    func fetchIdeas(for groupIdentifier: String) async -> Result<[Idea], SparkError> {
        .success(ideas.filter { $0.groupIdentifier == groupIdentifier })
    }

    func createIdea(_ idea: Idea, in groupIdentifier: String) async -> Result<Idea, SparkError> {
        ideas.append(idea)
        return .success(idea)
    }

    func updateIdea(_ idea: Idea) async -> Result<Idea, SparkError> {
        ideas.removeAll { $0.id == idea.id }
        ideas.append(idea)
        return .success(idea)
    }

    func deleteIdea(_ idea: Idea) async -> Result<Void, SparkError> {
        ideas.removeAll { $0.id == idea.id }
        votes.removeAll { $0.ideaIdentifier == idea.id }
        return .success(())
    }

    // MARK: - Votes

    func castVote(_ vote: Vote, on idea: Idea) async -> Result<Vote, SparkError> {
        votes.removeAll { $0.ideaIdentifier == vote.ideaIdentifier && $0.userIdentifier == vote.userIdentifier }
        votes.append(vote)
        return .success(vote)
    }

    func removeVote(_ vote: Vote, in groupIdentifier: String) async -> Result<Void, SparkError> {
        votes.removeAll { $0.id == vote.id }
        return .success(())
    }

    func votesForIdea(_ ideaIdentifier: String) async -> [Vote] {
        votes.filter { $0.ideaIdentifier == ideaIdentifier }
    }

    func fetchAllVotes(for groupIdentifier: String) async -> Result<[String: [Vote]], SparkError> {
        let groupIdeas = ideas.filter { $0.groupIdentifier == groupIdentifier }
        let ideaIds = Set(groupIdeas.map(\.id))
        let groupVotes = votes.filter { ideaIds.contains($0.ideaIdentifier) }
        let grouped = Dictionary(grouping: groupVotes, by: \.ideaIdentifier)
        return .success(grouped)
    }

    // MARK: - Planned Dates

    func fetchUpcomingDates(for groupIdentifier: String) async -> Result<[PlannedDate], SparkError> {
        let upcoming = plannedDates.filter { $0.groupIdentifier == groupIdentifier && $0.status == .planned && $0.date >= .now }
        return .success(upcoming.sorted { $0.date < $1.date })
    }

    func fetchPastDates(for groupIdentifier: String) async -> Result<[PlannedDate], SparkError> {
        let past = plannedDates.filter { $0.groupIdentifier == groupIdentifier && ($0.status == .completed || $0.date < .now) }
        return .success(past.sorted { $0.date > $1.date })
    }

    func createPlannedDate(_ plannedDate: PlannedDate, in groupIdentifier: String) async -> Result<PlannedDate, SparkError> {
        plannedDates.append(plannedDate)
        return .success(plannedDate)
    }

    func updatePlannedDate(_ plannedDate: PlannedDate) async -> Result<PlannedDate, SparkError> {
        plannedDates.removeAll { $0.id == plannedDate.id }
        plannedDates.append(plannedDate)
        return .success(plannedDate)
    }

    func deletePlannedDate(_ plannedDate: PlannedDate) async -> Result<Void, SparkError> {
        itinerarySteps.removeAll { $0.plannedDateIdentifier == plannedDate.id }
        journalEntries.removeAll { $0.plannedDateIdentifier == plannedDate.id }
        plannedDates.removeAll { $0.id == plannedDate.id }
        return .success(())
    }

    // MARK: - Itinerary Steps

    func fetchItinerarySteps(for plannedDate: PlannedDate) async -> Result<[ItineraryStep], SparkError> {
        let steps = itinerarySteps.filter { $0.plannedDateIdentifier == plannedDate.id }
        return .success(steps.sorted { $0.order < $1.order })
    }

    func createItineraryStep(_ step: ItineraryStep, for plannedDate: PlannedDate) async -> Result<ItineraryStep, SparkError> {
        itinerarySteps.append(step)
        return .success(step)
    }

    func updateItineraryStep(_ step: ItineraryStep) async -> Result<ItineraryStep, SparkError> {
        itinerarySteps.removeAll { $0.id == step.id }
        itinerarySteps.append(step)
        return .success(step)
    }

    func deleteItineraryStep(_ step: ItineraryStep) async -> Result<Void, SparkError> {
        itinerarySteps.removeAll { $0.id == step.id }
        return .success(())
    }

    // MARK: - Journal Entries

    func fetchJournalEntry(for plannedDate: PlannedDate) async -> Result<JournalEntry?, SparkError> {
        .success(journalEntries.first { $0.plannedDateIdentifier == plannedDate.id })
    }

    func createJournalEntry(_ entry: JournalEntry, for plannedDate: PlannedDate) async -> Result<JournalEntry, SparkError> {
        journalEntries.append(entry)
        return .success(entry)
    }

    func updateJournalEntry(_ entry: JournalEntry) async -> Result<JournalEntry, SparkError> {
        journalEntries.removeAll { $0.id == entry.id }
        journalEntries.append(entry)
        return .success(entry)
    }
}
