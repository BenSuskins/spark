import Foundation

final class FakeGroupRepository: GroupRepository, @unchecked Sendable {
    private var groups: [Group] = []
    private var shareURLs: [String: URL] = [:]

    func fetchGroups() async -> Result<[Group], SparkError> {
        .success(groups)
    }

    func createGroup(name: String, emoji: String) async -> Result<Group, SparkError> {
        let group = Group(
            id: UUID().uuidString,
            name: name,
            emoji: emoji,
            createdDate: .now,
            ownerIdentifier: "current-user"
        )
        groups.append(group)
        return .success(group)
    }

    func updateGroup(_ group: Group) async -> Result<Group, SparkError> {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else {
            return .failure(.recordNotFound)
        }
        groups[index] = group
        return .success(group)
    }

    func deleteGroup(_ group: Group) async -> Result<Void, SparkError> {
        groups.removeAll { $0.id == group.id }
        shareURLs.removeValue(forKey: group.id)
        return .success(())
    }

    func shareGroup(_ group: Group) async -> Result<URL, SparkError> {
        let url = URL(string: "https://share.spark.app/\(group.id)")!
        shareURLs[group.id] = url
        return .success(url)
    }

    func acceptShare(from url: URL) async -> Result<Group, SparkError> {
        let group = Group(
            id: UUID().uuidString,
            name: "Shared Group",
            emoji: "💞",
            createdDate: .now,
            ownerIdentifier: "other-user"
        )
        groups.append(group)
        return .success(group)
    }
}
