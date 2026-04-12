import SwiftUI

struct AddIdeaSheet: View {
    let model: IdeasModel

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var selectedCategory: IdeaCategory = .dining

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
                            dismiss()
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
