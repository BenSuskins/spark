import SwiftUI

struct JournalEntryView: View {
    @State var model: JournalModel
    @State private var rating: Int = 3
    @State private var notes: String = ""
    @State private var isEditing = false

    var body: some View {
        List {
            Section("Date") {
                LabeledContent("Title", value: model.plannedDate.title)
                LabeledContent("Date") {
                    Text(model.plannedDate.date, style: .date)
                }
            }

            if model.hasEntry && !isEditing {
                Section("Your Review") {
                    StarRatingDisplay(rating: model.entry?.rating ?? 0)

                    if let entryNotes = model.entry?.notes, !entryNotes.isEmpty {
                        Text(entryNotes)
                            .font(.body)
                    }

                    Button("Edit") {
                        rating = model.entry?.rating ?? 3
                        notes = model.entry?.notes ?? ""
                        isEditing = true
                    }
                }
            } else {
                Section(model.hasEntry ? "Edit Review" : "How was it?") {
                    StarRatingPicker(rating: $rating)

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(5)

                    Button(model.hasEntry ? "Update" : "Save") {
                        Task {
                            await model.saveEntry(rating: rating, notes: notes)
                            isEditing = false
                        }
                    }

                    if isEditing {
                        Button("Cancel", role: .cancel) {
                            isEditing = false
                        }
                    }
                }
            }
        }
        .navigationTitle("Journal")
        .task {
            await model.loadEntry()
            if let entry = model.entry {
                rating = entry.rating
                notes = entry.notes
            }
        }
    }
}

struct StarRatingPicker: View {
    @Binding var rating: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.title2)
                    .foregroundStyle(star <= rating ? .yellow : .secondary)
                    .onTapGesture {
                        rating = star
                    }
            }
        }
        .padding(.vertical, 4)
    }
}

struct StarRatingDisplay: View {
    let rating: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.body)
                    .foregroundStyle(star <= rating ? .yellow : .secondary)
            }
        }
    }
}
