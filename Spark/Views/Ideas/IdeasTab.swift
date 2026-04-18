import SwiftUI

struct IdeasTab: View {
    var model: IdeasModel
    var homeModel: HomeModel?
    var calendarModel: CalendarModel?
    var notificationModel: NotificationModel?

    @State private var showingAddIdea = false
    @State private var ideaToPlan: Idea?
    @State private var ideaToDelete: Idea?

    private var hasAnyIdeas: Bool {
        !model.ideasByCategory.values.allSatisfy { $0.isEmpty }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if hasAnyIdeas {
                        ForEach(IdeaCategory.allCases) { category in
                            let ideas = model.sortedIdeas(for: category)
                            if !ideas.isEmpty {
                                categorySection(category: category, ideas: ideas)
                            }
                        }
                    } else {
                        EmptyIdeas()
                            .padding(.top, 40)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(SparkColors.background)
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
            .sheet(item: $ideaToPlan, onDismiss: {
                Task { await model.loadIdeas() }
            }) { idea in
                if let homeModel {
                    PlanIdeaSheet(
                        idea: idea,
                        homeModel: homeModel,
                        calendarModel: calendarModel,
                        notificationModel: notificationModel
                    )
                }
            }
            .confirmationDialog(
                "Delete idea?",
                isPresented: Binding(
                    get: { ideaToDelete != nil },
                    set: { if !$0 { ideaToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
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
            .refreshable {
                await model.loadIdeas()
            }
        }
    }

    private func categorySection(category: IdeaCategory, ideas: [Idea]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(category.emoji)
                    .font(.title3)
                Text(category.rawValue)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(SparkColors.textPrimary)
                Spacer()
                Text("\(ideas.count)")
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(SparkColors.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(SparkColors.surface)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 4)

            VStack(spacing: 10) {
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
                                Label("Plan date", systemImage: "calendar.badge.plus")
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
}

private struct EmptyIdeas: View {
    var body: some View {
        VStack(spacing: 14) {
            Text("💡")
                .font(.system(size: 56))
            Text("No ideas yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(SparkColors.textPrimary)
            Text("Tap + to capture your first date idea.")
                .font(.subheadline)
                .foregroundStyle(SparkColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(SparkColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}
