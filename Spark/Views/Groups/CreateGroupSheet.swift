import SwiftUI

struct CreateGroupSheet: View {
    let model: GroupModel

    @Environment(\.dismiss) private var dismiss
    @State private var groupName = ""
    @State private var showingError = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("Group name", text: $groupName)
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            await model.createGroup(name: groupName)
                            if model.error == nil {
                                dismiss()
                            } else {
                                showingError = true
                            }
                        }
                    }
                    .disabled(groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
        .alert("Failed to Create Group", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(model.error?.localizedDescription ?? "An unknown error occurred.")
        }
    }
}
