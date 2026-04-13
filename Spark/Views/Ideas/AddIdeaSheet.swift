import SwiftUI

struct AddIdeaSheet: View {
    let model: IdeasModel

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var selectedCategory: IdeaCategory = .dining
    @State private var showingError = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("Idea title", text: $title)

                Picker("Category", selection: $selectedCategory) {
                    ForEach(IdeaCategory.allCases) { category in
                        Label(category.rawValue, systemImage: category.systemImage)
                            .tag(category)
                    }
                }
            }
            .navigationTitle("New Idea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await model.addIdea(title: title, category: selectedCategory)
                            if model.error == nil {
                                dismiss()
                            } else {
                                showingError = true
                            }
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
        .alert("Failed to Add Idea", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(model.error?.localizedDescription ?? "An unknown error occurred.")
        }
    }
}
