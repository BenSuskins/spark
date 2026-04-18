import Foundation
import Observation

/// Manages the user's group list and the currently-active group.
///
/// After the 4-tab redesign, the app always operates in the context of a
/// single selected group — there is no "All groups" view. Selection persists
/// across launches via `UserDefaults`.
@MainActor
@Observable
final class GroupModel {
    private(set) var groups: [Group] = []
    private(set) var isLoading = false
    private(set) var error: SparkError?

    var selectedGroup: Group?

    var selectedGroupIdentifier: String? { selectedGroup?.id }

    var groupIdentifiers: [String] { groups.map(\.id) }

    private let repository: GroupRepository
    private let defaults: UserDefaults
    private let selectedGroupKey = "selectedGroupIdentifier"

    init(repository: GroupRepository, defaults: UserDefaults = .standard) {
        self.repository = repository
        self.defaults = defaults
    }

    func loadGroups() async {
        isLoading = true
        let result = await repository.fetchGroups()

        if case .success(let loaded) = result {
            groups = loaded
            restoreSelection()
        } else if case .failure(let groupError) = result {
            error = groupError
        }

        isLoading = false
    }

    func createGroup(name: String, emoji: String = "💞") async {
        error = nil
        let result = await repository.createGroup(name: name, emoji: emoji)

        switch result {
        case .success(let group):
            await loadGroups()
            selectGroup(group)
        case .failure(let groupError):
            error = groupError
        }
    }

    func deleteGroup(_ group: Group) async {
        let result = await repository.deleteGroup(group)

        if case .success = result {
            if selectedGroup?.id == group.id {
                selectedGroup = groups.first { $0.id != group.id }
                persistSelection()
            }
            await loadGroups()
        }
    }

    func shareGroup(_ group: Group) async -> Result<URL, SparkError> {
        await repository.shareGroup(group)
    }

    func selectGroup(_ group: Group) {
        selectedGroup = group
        persistSelection()
    }

    // MARK: - Persistence

    private func persistSelection() {
        if let id = selectedGroup?.id {
            defaults.set(id, forKey: selectedGroupKey)
        } else {
            defaults.removeObject(forKey: selectedGroupKey)
        }
    }

    private func restoreSelection() {
        if let current = selectedGroup, groups.contains(where: { $0.id == current.id }) {
            return
        }

        let storedId = defaults.string(forKey: selectedGroupKey)
        selectedGroup = groups.first { $0.id == storedId } ?? groups.first
        persistSelection()
    }
}
