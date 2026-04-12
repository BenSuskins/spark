import SwiftUI

struct HomeTab: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Upcoming") {
                    ContentUnavailableView(
                        "No Upcoming Dates",
                        systemImage: "calendar",
                        description: Text("Plan a date from your ideas list")
                    )
                }

                Section("Recent") {
                    ContentUnavailableView(
                        "No Past Dates",
                        systemImage: "clock",
                        description: Text("Your date history will appear here")
                    )
                }
            }
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeTab()
}
