import SwiftUI

struct IdeasTab: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(IdeaCategory.allCases) { category in
                    Section(category.rawValue) {
                        ContentUnavailableView(
                            "No Ideas Yet",
                            systemImage: category.systemImage,
                            description: Text("Add your first \(category.rawValue.lowercased()) idea")
                        )
                    }
                }
            }
            .navigationTitle("Ideas")
        }
    }
}

#Preview {
    IdeasTab()
}
