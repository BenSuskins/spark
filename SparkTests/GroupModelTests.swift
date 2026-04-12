import Testing
@testable import Spark

@Test @MainActor func createGroupAddsToList() async {
    let repository = FakeGroupRepository()
    let model = GroupModel(repository: repository)

    await model.createGroup(name: "Date Night")

    #expect(model.groups.count == 1)
    #expect(model.groups.first?.name == "Date Night")
}

@Test @MainActor func loadGroupsFetchesAll() async {
    let repository = FakeGroupRepository()
    _ = await repository.createGroup(name: "Couple")
    _ = await repository.createGroup(name: "Friends")

    let model = GroupModel(repository: repository)
    await model.loadGroups()

    #expect(model.groups.count == 2)
}

@Test @MainActor func deleteGroupRemovesFromList() async {
    let repository = FakeGroupRepository()
    let model = GroupModel(repository: repository)
    await model.createGroup(name: "To Delete")

    let group = model.groups.first!
    await model.deleteGroup(group)

    #expect(model.groups.isEmpty)
}

@Test @MainActor func selectGroupUpdatesSelection() async {
    let repository = FakeGroupRepository()
    let model = GroupModel(repository: repository)
    await model.createGroup(name: "Group A")
    await model.createGroup(name: "Group B")

    let groupB = model.groups.last!
    model.selectGroup(groupB)

    #expect(model.selectedGroup?.name == "Group B")
}

@Test @MainActor func selectNilShowsAllGroups() async {
    let repository = FakeGroupRepository()
    let model = GroupModel(repository: repository)
    await model.createGroup(name: "Group A")

    model.selectGroup(model.groups.first!)
    #expect(model.selectedGroup != nil)

    model.selectAllGroups()
    #expect(model.selectedGroup == nil)
    #expect(model.isShowingAllGroups)
}

@Test @MainActor func shareGroupReturnsURL() async {
    let repository = FakeGroupRepository()
    let model = GroupModel(repository: repository)
    await model.createGroup(name: "Shareable")

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
    let model = GroupModel(repository: repository)
    await model.createGroup(name: "A")
    await model.createGroup(name: "B")

    #expect(model.groupIdentifiers.count == 2)
}

@Test @MainActor func selectedGroupIdentifierReflectsSelection() async {
    let repository = FakeGroupRepository()
    let model = GroupModel(repository: repository)
    await model.createGroup(name: "Only One")

    model.selectGroup(model.groups.first!)
    #expect(model.selectedGroupIdentifier == model.groups.first?.id)

    model.selectAllGroups()
    #expect(model.selectedGroupIdentifier == nil)
}
