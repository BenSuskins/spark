import Foundation
import Observation

@MainActor
@Observable
final class GroupModel {
    private(set) var groups: [Group] = []
    private(set) var isLoading = false
    private(set) var error: SparkError?

    var selectedGroup: Group?

    var isShowingAllGroups: Bool { selectedGroup == nil }

    var selectedGroupIdentifier: String? { selectedGroup?.id }

    var groupIdentifiers: [String] { groups.map(\.id) }

    private let repository: GroupRepository

    init(repository: GroupRepository) {
        self.repository = repository
    }

    func loadGroups() async {
        isLoading = true
        let result = await repository.fetchGroups()

        if case .success(let loaded) = result {
            groups = loaded
        } else if case .failure(let groupError) = result {
            error = groupError
        }

        isLoading = false
    }

    func createGroup(name: String) async {
        let result = await repository.createGroup(name: name)

        if case .success = result {
            await loadGroups()
        }
    }

    func deleteGroup(_ group: Group) async {
        let result = await repository.deleteGroup(group)

        if case .success = result {
            if selectedGroup?.id == group.id {
                selectedGroup = nil
            }
            await loadGroups()
        }
    }

    func shareGroup(_ group: Group) async -> Result<URL, SparkError> {
        await repository.shareGroup(group)
    }

    func selectGroup(_ group: Group) {
        selectedGroup = group
    }

    func selectAllGroups() {
        selectedGroup = nil
    }
}
