import SwiftUI

struct EditGroupSheet: View {
    let model: GroupModel
    let group: Group

    @Environment(\.dismiss) private var dismiss
    @State private var groupName: String
    @State private var emoji: String
    @State private var isSaving = false
    @State private var showingError = false

    init(model: GroupModel, group: Group) {
        self.model = model
        self.group = group
        _groupName = State(initialValue: group.name)
        _emoji = State(initialValue: group.emoji)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                EmojiPickerChip(emoji: $emoji)
                    .frame(maxWidth: .infinity)

                SparkFormField(title: "Group name") {
                    TextField("Our Dates", text: $groupName)
                        .font(.body)
                }

                Spacer()

                Button {
                    save()
                } label: {
                    if isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Text("Save")
                    }
                }
                .buttonStyle(SparkPrimaryButtonStyle())
                .disabled(!canSave)
            }
            .padding(20)
            .navigationTitle("Edit group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .alert("Couldn't save group", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(model.error?.localizedDescription ?? "An unknown error occurred.")
        }
    }

    private var canSave: Bool {
        let trimmed = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return !isSaving && (trimmed != group.name || emoji != group.emoji)
    }

    private func save() {
        guard !isSaving else { return }
        isSaving = true
        let updated = Group(
            id: group.id,
            name: groupName.trimmingCharacters(in: .whitespacesAndNewlines),
            emoji: emoji,
            createdDate: group.createdDate,
            ownerIdentifier: group.ownerIdentifier
        )
        Task {
            await model.updateGroup(updated)
            isSaving = false
            if model.error == nil {
                dismiss()
            } else {
                showingError = true
            }
        }
    }
}
