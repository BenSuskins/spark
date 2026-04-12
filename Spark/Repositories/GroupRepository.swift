import Foundation

protocol GroupRepository: Sendable {
    func fetchGroups() async -> Result<[Group], SparkError>
    func createGroup(name: String) async -> Result<Group, SparkError>
    func deleteGroup(_ group: Group) async -> Result<Void, SparkError>
    func shareGroup(_ group: Group) async -> Result<URL, SparkError>
    func acceptShare(from url: URL) async -> Result<Group, SparkError>
}
