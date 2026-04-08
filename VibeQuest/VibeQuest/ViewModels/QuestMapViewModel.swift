import Foundation
import SwiftUI
import MapKit
import CoreLocation

@MainActor
final class QuestMapViewModel: ObservableObject {
    @Published var quests: [Quest] = []
    @Published var selectedQuest: Quest?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964), // Rome default
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    private let firestoreService = FirestoreService.shared
    private let locationService = LocationService.shared
    private var questStreamTask: Task<Void, Never>?

    func startListening() {
        locationService.requestPermission()
        locationService.startUpdating()

        questStreamTask = Task {
            for await quests in firestoreService.streamOpenQuests() {
                self.quests = quests
            }
        }
    }

    func stopListening() {
        questStreamTask?.cancel()
        questStreamTask = nil
    }

    func centerOnUser() {
        if let location = locationService.userLocation {
            withAnimation {
                region = MKCoordinateRegion(
                    center: location,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            }
        }
    }

    func selectQuest(_ quest: Quest) {
        selectedQuest = quest
    }

    func clearSelection() {
        selectedQuest = nil
    }

    func distanceToQuest(_ quest: Quest) -> String? {
        let coord = CLLocationCoordinate2D(latitude: quest.latitude, longitude: quest.longitude)
        guard let meters = locationService.distance(from: coord) else { return nil }
        return FormatUtils.distanceString(meters)
    }
}
