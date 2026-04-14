import SwiftUI
import MapKit

struct VenueDetailSheet: View {
    let venue: Venue
    let model: DiscoverModel

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: IdeaCategory = .dining
    @State private var addedSuccessfully = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Map {
                        Marker(venue.name, coordinate: venue.coordinate)
                    }
                    .frame(height: 180)
                    .listRowInsets(EdgeInsets())
                }

                Section {
                    LabeledContent("Name", value: venue.name)

                    if let address = venue.address {
                        LabeledContent("Address", value: address)
                    }

                    if let category = venue.category {
                        LabeledContent("Category", value: category)
                    }
                }

                Section("Add to Ideas") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(IdeaCategory.allCases) { category in
                            Label(category.rawValue, systemImage: category.systemImage)
                                .tag(category)
                        }
                    }

                    Button {
                        Task {
                            let result = await model.addVenueAsIdea(venue, category: selectedCategory)
                            if case .success = result {
                                addedSuccessfully = true
                            }
                        }
                    } label: {
                        if addedSuccessfully {
                            Label("Added to Ideas", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(SparkColors.success)
                        } else {
                            Label("Add to Ideas List", systemImage: "plus.circle")
                        }
                    }
                    .disabled(addedSuccessfully)
                }
            }
            .navigationTitle(venue.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
