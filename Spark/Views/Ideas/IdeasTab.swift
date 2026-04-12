import SwiftUI

struct IdeasTab: View {
    @State var model: IdeasModel
    var homeModel: HomeModel?
    @State private var showingAddIdea = false
    @State private var ideaToPlan: Idea?

    var body: some View {
        NavigationStack {
            List {
                ForEach(IdeaCategory.allCases) { category in
                    let ideas = model.sortedIdeas(for: category)

                    if !ideas.isEmpty {
                        Section(category.rawValue) {
                            ForEach(ideas) { idea in
                                IdeaRow(
                                    idea: idea,
                                    score: model.score(for: idea.id),
                                    currentUserVote: model.currentUserVote(for: idea.id),
                                    onUpvote: { Task { await model.toggleVote(on: idea, value: 1) } },
                                    onDownvote: { Task { await model.toggleVote(on: idea, value: -1) } }
                                )
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    if homeModel != nil {
                                        Button {
                                            ideaToPlan = idea
                                        } label: {
                                            Label("Plan", systemImage: "calendar.badge.plus")
                                        }
                                        .tint(.blue)
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Task { await model.deleteIdea(idea) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }

                if model.ideasByCategory.values.allSatisfy({ $0.isEmpty }) {
                    ContentUnavailableView(
                        "No Ideas Yet",
                        systemImage: "lightbulb",
                        description: Text("Tap + to add your first date idea")
                    )
                }
            }
            .navigationTitle("Ideas")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddIdea = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddIdea) {
                AddIdeaSheet(model: model)
            }
            .sheet(item: $ideaToPlan) { idea in
                if let homeModel {
                    PlanIdeaSheet(idea: idea, homeModel: homeModel)
                }
            }
            .task {
                await model.loadIdeas()
            }
        }
    }
}

#Preview {
    IdeasTab(model: IdeasModel(
        repository: FakeDateRepository(),
        groupIdentifier: "preview-group",
        currentUserIdentifier: "preview-user"
    ))
}
