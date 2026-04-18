import Testing
import Foundation
@testable import Spark

private func makeDefaults() -> UserDefaults {
    let suiteName = "GroupModelTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
}

@Test @MainActor func createGroupAddsToListAndSelects() async {
    let repository = FakeGroupRepository()
    let model = GroupModel(repository: repository, defaults: makeDefaults())

    await model.createGroup(name: "Date Night", emoji: "🌙")

    #expect(model.groups.count == 1)
    #expect(model.groups.first?.name == "Date Night")
    #expect(model.groups.first?.emoji == "🌙")
    #expect(model.selectedGroup?.id == model.groups.first?.id)
}

@Test @MainActor func loadGroupsFetchesAllAndSelectsFirst() async {
    let repository = FakeGroupRepository()
    _ = await repository.createGroup(name: "Couple", emoji: "💞")
    _ = await repository.createGroup(name: "Friends", emoji: "🎉")

    let model = GroupModel(repository: repository, defaults: makeDefaults())
    await model.loadGroups()

    #expect(model.groups.count == 2)
    #expect(model.selectedGroup != nil)
}

@Test @MainActor func deleteGroupRemovesFromListAndReassignsSelection() async {
    let repository = FakeGroupRepository()
    let model = GroupModel(repository: repository, defaults: makeDefaults())
    await model.createGroup(name: "First", emoji: "💞")
    await model.createGroup(name: "Second", emoji: "🎉")

    let selected = model.selectedGroup!
    await model.deleteGroup(selected)

    #expect(model.groups.count == 1)
    #expect(model.selectedGroup?.id != selected.id)
}

@Test @MainActor func selectGroupUpdatesSelection() async {
    let repository = FakeGroupRepository()
    let model = GroupModel(repository: repository, defaults: makeDefaults())
    await model.createGroup(name: "Group A", emoji: "💞")
    await model.createGroup(name: "Group B", emoji: "🔥")

    let groupB = model.groups.first { $0.name == "Group B" }!
    model.selectGroup(groupB)

    #expect(model.selectedGroup?.name == "Group B")
}

@Test @MainActor func selectionPersistsAcrossReloads() async {
    let repository = FakeGroupRepository()
    let defaults = makeDefaults()
    let model = GroupModel(repository: repository, defaults: defaults)

    await model.createGroup(name: "Group A", emoji: "💞")
    await model.createGroup(name: "Group B", emoji: "🔥")
    let groupB = model.groups.first { $0.name == "Group B" }!
    model.selectGroup(groupB)

    let reloaded = GroupModel(repository: repository, defaults: defaults)
    await reloaded.loadGroups()

    #expect(reloaded.selectedGroup?.id == groupB.id)
}

@Test @MainActor func shareGroupReturnsURL() async {
    let repository = FakeGroupRepository()
    let model = GroupModel(repository: repository, defaults: makeDefaults())
    await model.createGroup(name: "Shareable", emoji: "💞")

    let group = model.groups.first!
    let result = await model.shareGroup(group)

    switch result {
    case .success(let url):
        #expect(url.absoluteString.contains(group.id))
    case .failure:
        Issue.record("Expected success")
    }
}

@Test @MainActor func groupIdentifiersReturnsAllIds() async {
    let repository = FakeGroupRepository()
    let model = GroupModel(repository: repository, defaults: makeDefaults())
    await model.createGroup(name: "A", emoji: "💞")
    await model.createGroup(name: "B", emoji: "🔥")

    #expect(model.groupIdentifiers.count == 2)
}

@Test @MainActor func selectedGroupIdentifierReflectsSelection() async {
    let repository = FakeGroupRepository()
    let model = GroupModel(repository: repository, defaults: makeDefaults())
    await model.createGroup(name: "Only One", emoji: "💞")

    model.selectGroup(model.groups.first!)
    #expect(model.selectedGroupIdentifier == model.groups.first?.id)
}
