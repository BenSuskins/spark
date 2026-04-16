import SwiftUI

struct IdeasTab: View {
    var model: IdeasModel
    var homeModel: HomeModel?
    var calendarModel: CalendarModel?
    var notificationModel: NotificationModel?
    var groupPickerMenu: GroupPickerMenu?
    @State private var showingAddIdea = false
    @State private var ideaToPlan: Idea?
    @State private var ideaToDelete: Idea?

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
                                .contextMenu {
                                    if homeModel != nil {
                                        Button {
                                            ideaToPlan = idea
                                        } label: {
                                            Label("Plan Date", systemImage: "calendar.badge.plus")
                                        }
                                    }
                                    Button(role: .destructive) {
                                        ideaToDelete = idea
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
                if let groupPickerMenu {
                    ToolbarItem(placement: .topBarLeading) {
                        groupPickerMenu
                    }
                }
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
            .sheet(item: $ideaToPlan, onDismiss: {
                Task { await model.loadIdeas() }
            }) { idea in
                if let homeModel {
                    PlanIdeaSheet(idea: idea, homeModel: homeModel, calendarModel: calendarModel, notificationModel: notificationModel)
                }
            }
            .confirmationDialog("Delete Idea", isPresented: Binding(
                get: { ideaToDelete != nil },
                set: { if !$0 { ideaToDelete = nil } }
            ), titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let idea = ideaToDelete {
                        Task { await model.deleteIdea(idea) }
                    }
                }
            } message: {
                Text("This idea and all its votes will be permanently deleted.")
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
