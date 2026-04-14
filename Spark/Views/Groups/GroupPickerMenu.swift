import SwiftUI

struct GroupPickerMenu: View {
    @Bindable var model: GroupModel
    var calendarModel: CalendarModel?
    var notificationModel: NotificationModel?
    var locationModel: LocationModel?
    @State private var showingGroupSettings = false

    var body: some View {
        Menu {
            Button {
                model.selectAllGroups()
            } label: {
                if model.isShowingAllGroups {
                    Label("All Groups", systemImage: "checkmark")
                } else {
                    Text("All Groups")
                }
            }

            Divider()

            ForEach(model.groups) { group in
                Button {
                    model.selectGroup(group)
                } label: {
                    if model.selectedGroup?.id == group.id {
                        Label(group.name, systemImage: "checkmark")
                    } else {
                        Text(group.name)
                    }
                }
            }

            Divider()

            Button {
                showingGroupSettings = true
            } label: {
                Label("Settings", systemImage: "gear")
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "person.2")
                Text(model.selectedGroup?.name ?? "All Groups")
                    .lineLimit(1)
            }
            .font(.subheadline)
        }
        .sheet(isPresented: $showingGroupSettings) {
            GroupSettingsView(model: model, calendarModel: calendarModel, notificationModel: notificationModel, locationModel: locationModel)
        }
    }
}
