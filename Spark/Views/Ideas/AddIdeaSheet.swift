import SwiftUI

/// Two-step, category-led add flow:
///   1. Pick a category via big emoji tiles
///   2. Title the idea
struct AddIdeaSheet: View {
    let model: IdeasModel

    @Environment(\.dismiss) private var dismiss
    @State private var step: Step = .category
    @State private var selectedCategory: IdeaCategory?
    @State private var title = ""
    @FocusState private var titleFocused: Bool
    @State private var showingError = false

    enum Step { case category, details }

    var body: some View {
        NavigationStack {
            SwiftUI.Group {
                switch step {
                case .category: categoryStep
                case .details: detailsStep
                }
            }
            .background(SparkColors.background)
            .navigationTitle(step == .category ? "Pick a vibe" : "Name it")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if step == .details {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add", action: saveIdea)
                            .disabled(!canSave)
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .alert("Failed to Add Idea", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(model.error?.localizedDescription ?? "An unknown error occurred.")
        }
    }

    private var canSave: Bool {
        selectedCategory != nil && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Step 1: category

    private var categoryStep: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                ForEach(IdeaCategory.allCases) { category in
                    CategoryTile(category: category, isSelected: selectedCategory == category) {
                        withAnimation(SparkSprings.standard) {
                            selectedCategory = category
                        }
                        Task {
                            try? await Task.sleep(for: .milliseconds(180))
                            await MainActor.run {
                                withAnimation(SparkSprings.sheet) { step = .details }
                                titleFocused = true
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    // MARK: - Step 2: title

    private var detailsStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let category = selectedCategory {
                    HStack(spacing: 14) {
                        Text(category.emoji)
                            .font(.system(size: 36))
                            .frame(width: 64, height: 64)
                            .background(SparkColors.accentMuted)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.rawValue)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(SparkColors.textPrimary)
                            Button("Change vibe") {
                                withAnimation(SparkSprings.sheet) { step = .category }
                            }
                            .buttonStyle(SparkGhostButtonStyle())
                        }
                        Spacer()
                    }
                    .padding(14)
                    .sparkCard(cornerRadius: 20)
                }

                SparkFormField(title: "What's the idea?") {
                    TextField("Pasta at that little place on 5th", text: $title, axis: .vertical)
                        .lineLimit(2...5)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(SparkColors.textPrimary)
                        .focused($titleFocused)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Save

    private func saveIdea() {
        guard let category = selectedCategory else { return }
        Task {
            await model.addIdea(title: title, category: category)
            if model.error == nil {
                dismiss()
            } else {
                showingError = true
            }
        }
    }
}

private struct CategoryTile: View {
    let category: IdeaCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(category.emoji)
                    .font(.system(size: 48))
                Text(category.rawValue)
                    .font(.headline)
                    .foregroundStyle(SparkColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(isSelected ? SparkColors.accentMuted : SparkColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isSelected ? SparkColors.accent : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
