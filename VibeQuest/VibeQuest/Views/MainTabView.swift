import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MapScreen()
                .tabItem {
                    Label("Explore", systemImage: "map.fill")
                }
                .tag(0)

            MyQuestsScreen()
                .tabItem {
                    Label("My Quests", systemImage: "list.bullet.rectangle.fill")
                }
                .tag(1)

            CreateQuestScreen()
                .tabItem {
                    Label("Create", systemImage: "plus.circle.fill")
                }
                .tag(2)

            ProfileScreen()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .tint(VQTheme.primary)
    }
}
