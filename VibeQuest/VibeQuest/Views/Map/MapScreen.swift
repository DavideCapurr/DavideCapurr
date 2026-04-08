import SwiftUI
import MapKit

struct MapScreen: View {
    @StateObject private var viewModel = QuestMapViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var showCreateQuest = false

    var body: some View {
        NavigationStack {
            ZStack {
                VQTheme.background.ignoresSafeArea()

                // Map
                Map(coordinateRegion: $viewModel.region, annotationItems: viewModel.quests) { quest in
                    MapAnnotation(coordinate: CLLocationCoordinate2D(
                        latitude: quest.latitude,
                        longitude: quest.longitude
                    )) {
                        QuestPin(quest: quest)
                            .onTapGesture {
                                viewModel.selectQuest(quest)
                            }
                    }
                }
                .ignoresSafeArea(edges: .top)

                // Controls overlay
                VStack {
                    Spacer()

                    // My location button
                    HStack {
                        Spacer()
                        Button {
                            viewModel.centerOnUser()
                        } label: {
                            Image(systemName: "location.fill")
                                .font(.title3)
                                .foregroundStyle(VQTheme.cyan)
                                .padding(12)
                                .background(VQTheme.surface)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 4)
                        }
                        .padding(.trailing, VQTheme.paddingMd)
                        .padding(.bottom, 8)
                    }

                    // Quest cards bottom sheet
                    if !viewModel.quests.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.quests) { quest in
                                    QuestCard(
                                        quest: quest,
                                        distance: viewModel.distanceToQuest(quest)
                                    ) {
                                        viewModel.selectQuest(quest)
                                    }
                                    .frame(width: 300)
                                }
                            }
                            .padding(.horizontal, VQTheme.paddingMd)
                        }
                        .padding(.bottom, VQTheme.paddingSm)
                    }
                }
            }
            .navigationTitle("VibeQuest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(VQTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $viewModel.selectedQuest) { quest in
                QuestDetailSheet(quest: quest)
                    .environmentObject(authViewModel)
            }
            .onAppear {
                viewModel.startListening()
            }
            .onDisappear {
                viewModel.stopListening()
            }
        }
    }
}

// MARK: - Quest Pin

struct QuestPin: View {
    let quest: Quest

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(pinColor.opacity(0.3))
                    .frame(width: 44, height: 44)

                Circle()
                    .fill(pinColor)
                    .frame(width: 32, height: 32)

                Image(systemName: quest.taskType.icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Pin tail
            Triangle()
                .fill(pinColor)
                .frame(width: 12, height: 8)
        }
        .shadow(color: pinColor.opacity(0.5), radius: 6)
    }

    private var pinColor: Color {
        quest.tier == .micro ? VQTheme.microColor : VQTheme.macroColor
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
