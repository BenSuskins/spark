import SwiftUI

struct CreateGroupSheet: View {
    let model: GroupModel

    @Environment(\.dismiss) private var dismiss
    @State private var groupName = ""
    @State private var emoji = "💞"
    @State private var showingError = false

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

                Button("Create") {
                    Task {
                        await model.createGroup(name: groupName, emoji: emoji)
                        if model.error == nil {
                            dismiss()
                        } else {
                            showingError = true
                        }
                    }
                }
                .buttonStyle(SparkPrimaryButtonStyle())
                .disabled(groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(20)
            .navigationTitle("New group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .alert("Couldn't create group", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(model.error?.localizedDescription ?? "An unknown error occurred.")
        }
    }
}

/// A big circular emoji bubble you tap to change the group's emoji via the
/// system emoji keyboard.
struct EmojiPickerChip: View {
    @Binding var emoji: String
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [SparkColors.accent.opacity(0.9), SparkColors.accent.opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)

            Text(emoji.isEmpty ? "💞" : emoji)
                .font(.system(size: 64))

            // Hidden text field that accepts emoji input.
            TextField("", text: $emoji)
                .focused($focused)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .onChange(of: emoji) { _, newValue in
                    let first = newValue.unicodeScalars.first.map { String($0) } ?? "💞"
                    if newValue != first {
                        emoji = String(newValue.prefix(1))
                    }
                    if !newValue.isEmpty { focused = false }
                }
        }
        .contentShape(Circle())
        .onTapGesture { focused = true }
        .shadow(color: .black.opacity(0.08), radius: 24, y: 8)
    }
}
