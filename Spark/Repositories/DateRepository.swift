import Foundation

protocol DateRepository: Sendable {
    func fetchUpcomingDates(for groupIdentifier: String) async -> Result<[PlannedDate], SparkError>
    func fetchPastDates(for groupIdentifier: String) async -> Result<[PlannedDate], SparkError>
    func createPlannedDate(_ plannedDate: PlannedDate, in groupIdentifier: String) async -> Result<PlannedDate, SparkError>
    func updatePlannedDate(_ plannedDate: PlannedDate) async -> Result<PlannedDate, SparkError>
    func deletePlannedDate(_ plannedDate: PlannedDate) async -> Result<Void, SparkError>

    func fetchIdeas(for groupIdentifier: String) async -> Result<[Idea], SparkError>
    func createIdea(_ idea: Idea, in groupIdentifier: String) async -> Result<Idea, SparkError>
    func deleteIdea(_ idea: Idea) async -> Result<Void, SparkError>

    func castVote(_ vote: Vote, on idea: Idea) async -> Result<Vote, SparkError>
    func removeVote(_ vote: Vote) async -> Result<Void, SparkError>

    func fetchItinerarySteps(for plannedDate: PlannedDate) async -> Result<[ItineraryStep], SparkError>
    func createItineraryStep(_ step: ItineraryStep, for plannedDate: PlannedDate) async -> Result<ItineraryStep, SparkError>
    func updateItineraryStep(_ step: ItineraryStep) async -> Result<ItineraryStep, SparkError>
    func deleteItineraryStep(_ step: ItineraryStep) async -> Result<Void, SparkError>

    func fetchJournalEntry(for plannedDate: PlannedDate) async -> Result<JournalEntry?, SparkError>
    func createJournalEntry(_ entry: JournalEntry, for plannedDate: PlannedDate) async -> Result<JournalEntry, SparkError>
    func updateJournalEntry(_ entry: JournalEntry) async -> Result<JournalEntry, SparkError>
}
