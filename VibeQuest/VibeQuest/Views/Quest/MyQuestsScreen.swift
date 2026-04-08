import SwiftUI

struct MyQuestsScreen: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            ZStack {
                VQTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Segmented control
                    Picker("", selection: $selectedTab) {
                        Text("Created").tag(0)
                        Text("Accepted").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, VQTheme.paddingLg)
                    .padding(.vertical, VQTheme.paddingSm)

                    if selectedTab == 0 {
                        questList(quests: viewModel.createdQuests, emptyMessage: "No quests created yet")
                    } else {
                        questList(quests: viewModel.acceptedQuests, emptyMessage: "No quests accepted yet")
                    }
                }
            }
            .navigationTitle("My Quests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(VQTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                if let uid = authViewModel.currentUserId {
                    viewModel.startListeningQuests(userId: uid)
                }
            }
            .onDisappear {
                viewModel.stopListening()
            }
        }
    }

    @ViewBuilder
    private func questList(quests: [Quest], emptyMessage: String) -> some View {
        if quests.isEmpty {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "tray")
                    .font(.system(size: 48))
                    .foregroundStyle(VQTheme.textSecondary)
                Text(emptyMessage)
                    .font(.headline)
                    .foregroundStyle(VQTheme.textSecondary)
                Spacer()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(quests) { quest in
                        NavigationLink {
                            QuestDetailSheet(quest: quest)
                                .environmentObject(authViewModel)
                        } label: {
                            QuestCard(quest: quest)
                        }
                    }
                }
                .padding(.horizontal, VQTheme.paddingMd)
                .padding(.top, VQTheme.paddingSm)
            }
        }
    }
}
