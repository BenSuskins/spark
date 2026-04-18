import SwiftUI

/// Journal entry for a past date. The note is a single String in the domain
/// model, but the UI presents it as three guided prompts that compose into
/// labeled sections. Legacy notes (no labels) are loaded into the first prompt.
struct JournalEntryView: View {
    @State var model: JournalModel
    @State private var rating: Int = 3
    @State private var favoriteMoment: String = ""
    @State private var surprise: String = ""
    @State private var forNextTime: String = ""
    @State private var isEditing = true
    @State private var showingError = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ratingCard

                if isEditing {
                    editingPrompts
                    saveButtons
                } else {
                    readOnlySummary
                }
            }
            .padding(16)
        }
        .background(SparkColors.background)
        .navigationTitle("Journal")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Failed to Save Entry", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(model.error?.localizedDescription ?? "An unknown error occurred.")
        }
        .task {
            await model.loadEntry()
            if let entry = model.entry {
                rating = entry.rating
                let parsed = JournalNotes.parse(entry.notes)
                favoriteMoment = parsed.favoriteMoment
                surprise = parsed.surprise
                forNextTime = parsed.forNextTime
                isEditing = false
            }
        }
    }

    // MARK: - Sections

    private var ratingCard: some View {
        VStack(spacing: 14) {
            Text("How was it?")
                .font(.headline)
                .foregroundStyle(SparkColors.textPrimary)
            BigStarPicker(rating: $rating, isInteractive: isEditing)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .sparkCard(cornerRadius: 24)
    }

    private var editingPrompts: some View {
        VStack(spacing: 16) {
            PromptField(
                emoji: "💖",
                title: "Favorite moment?",
                placeholder: "The bit that made you smile",
                text: $favoriteMoment
            )
            PromptField(
                emoji: "😮",
                title: "What surprised you?",
                placeholder: "An unexpected detail, in hindsight",
                text: $surprise
            )
            PromptField(
                emoji: "📝",
                title: "For next time?",
                placeholder: "Something you'd do differently",
                text: $forNextTime
            )
        }
    }

    private var saveButtons: some View {
        VStack(spacing: 10) {
            Button(model.hasEntry ? "Update" : "Save") {
                Task {
                    let composed = JournalNotes.compose(
                        favoriteMoment: favoriteMoment,
                        surprise: surprise,
                        forNextTime: forNextTime
                    )
                    await model.saveEntry(rating: rating, notes: composed)
                    if model.error == nil {
                        isEditing = false
                    } else {
                        showingError = true
                    }
                }
            }
            .buttonStyle(SparkPrimaryButtonStyle())

            if model.hasEntry {
                Button("Cancel") {
                    restoreFromEntry()
                    isEditing = false
                }
                .buttonStyle(SparkGhostButtonStyle())
            }
        }
        .padding(.top, 4)
    }

    private var readOnlySummary: some View {
        VStack(spacing: 12) {
            SummaryCard(emoji: "💖", title: "Favorite moment", text: favoriteMoment)
            SummaryCard(emoji: "😮", title: "What surprised you", text: surprise)
            SummaryCard(emoji: "📝", title: "For next time", text: forNextTime)

            Button("Edit") { isEditing = true }
                .buttonStyle(SparkGhostButtonStyle())
                .padding(.top, 4)
        }
    }

    private func restoreFromEntry() {
        guard let entry = model.entry else { return }
        rating = entry.rating
        let parsed = JournalNotes.parse(entry.notes)
        favoriteMoment = parsed.favoriteMoment
        surprise = parsed.surprise
        forNextTime = parsed.forNextTime
    }
}

// MARK: - Prompt field

private struct PromptField: View {
    let emoji: String
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(emoji).font(.title3)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(SparkColors.textPrimary)
            }
            TextField(placeholder, text: $text, axis: .vertical)
                .lineLimit(3...8)
                .font(.body)
                .foregroundStyle(SparkColors.textPrimary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sparkCard(cornerRadius: 20)
    }
}

private struct SummaryCard: View {
    let emoji: String
    let title: String
    let text: String

    var resolvedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "—" : text
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(emoji).font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SparkColors.textSecondary)
                    .textCase(.uppercase)
                Text(resolvedText)
                    .font(.body)
                    .foregroundStyle(SparkColors.textPrimary)
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sparkCard(cornerRadius: 20)
    }
}

// MARK: - Big star picker

struct BigStarPicker: View {
    @Binding var rating: Int
    var isInteractive: Bool = true

    var body: some View {
        HStack(spacing: 10) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(star <= rating ? SparkColors.accent : SparkColors.textTertiary)
                    .contentTransition(.symbolEffect(.replace))
                    .onTapGesture {
                        guard isInteractive else { return }
                        withAnimation(SparkSprings.standard) { rating = star }
                    }
            }
        }
    }
}

// MARK: - Compose / parse

/// Serializes three guided-prompt fields into a single `notes` string and
/// back. Legacy notes with no labels fall into `favoriteMoment`.
enum JournalNotes {
    struct Parsed {
        var favoriteMoment: String
        var surprise: String
        var forNextTime: String
    }

    private static let favoriteMomentLabel = "Favorite moment:"
    private static let surpriseLabel = "What surprised us:"
    private static let forNextTimeLabel = "For next time:"

    static func compose(favoriteMoment: String, surprise: String, forNextTime: String) -> String {
        var parts: [String] = []
        if !favoriteMoment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append("\(favoriteMomentLabel) \(favoriteMoment)")
        }
        if !surprise.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append("\(surpriseLabel) \(surprise)")
        }
        if !forNextTime.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append("\(forNextTimeLabel) \(forNextTime)")
        }
        return parts.joined(separator: "\n\n")
    }

    static func parse(_ notes: String) -> Parsed {
        let labels = [favoriteMomentLabel, surpriseLabel, forNextTimeLabel]
        let hasAny = labels.contains(where: { notes.contains($0) })
        guard hasAny else {
            return Parsed(favoriteMoment: notes, surprise: "", forNextTime: "")
        }
        return Parsed(
            favoriteMoment: extract(favoriteMomentLabel, from: notes),
            surprise: extract(surpriseLabel, from: notes),
            forNextTime: extract(forNextTimeLabel, from: notes)
        )
    }

    private static func extract(_ label: String, from notes: String) -> String {
        guard let range = notes.range(of: label) else { return "" }
        let afterLabel = notes[range.upperBound...]
        let otherLabels = [favoriteMomentLabel, surpriseLabel, forNextTimeLabel].filter { $0 != label }
        var end = afterLabel.endIndex
        for other in otherLabels {
            if let otherRange = afterLabel.range(of: other), otherRange.lowerBound < end {
                end = otherRange.lowerBound
            }
        }
        return afterLabel[..<end].trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
