import SwiftUI

struct PlanIdeaSheet: View {
    let idea: Idea
    let homeModel: HomeModel

    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var didCreate = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Idea", value: idea.title)
                    LabeledContent("Category", value: idea.category.rawValue)
                }

                Section {
                    DatePicker("Date & Time", selection: $selectedDate)
                }

                if didCreate {
                    Section {
                        Label("Date planned!", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("Plan Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            let result = await homeModel.promoteIdeaToDate(idea, date: selectedDate)
                            if case .success = result {
                                didCreate = true
                                try? await Task.sleep(for: .seconds(0.8))
                                dismiss()
                            }
                        }
                    }
                    .disabled(didCreate)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
