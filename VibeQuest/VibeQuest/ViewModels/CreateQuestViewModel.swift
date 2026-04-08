import Foundation
import MapKit
import CoreLocation

@MainActor
final class CreateQuestViewModel: ObservableObject {
    // Step state
    @Published var currentStep = 0

    // Quest fields
    @Published var title = ""
    @Published var description = ""
    @Published var taskType: TaskType = .photo
    @Published var tier: QuestTier = .micro
    @Published var pinCoordinate: CLLocationCoordinate2D?

    // UI state
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var isCompleted = false

    @Published var pinRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    private let firestoreService = FirestoreService.shared
    private let locationService = LocationService.shared

    let totalSteps = 4

    init() {
        if let loc = locationService.userLocation {
            pinCoordinate = loc
            pinRegion = MKCoordinateRegion(
                center: loc,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }

    var canProceed: Bool {
        switch currentStep {
        case 0: return pinCoordinate != nil
        case 1: return true // taskType always has a value
        case 2: return true // tier always has a value
        case 3: return !title.trimmingCharacters(in: .whitespaces).isEmpty
        default: return false
        }
    }

    func nextStep() {
        if currentStep < totalSteps - 1 {
            currentStep += 1
        }
    }

    func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }

    func createQuest(requesterId: String) async {
        guard let coordinate = pinCoordinate else { return }

        isSubmitting = true
        errorMessage = nil

        let quest = Quest(
            requesterId: requesterId,
            title: title.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            taskType: taskType,
            tier: tier,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )

        do {
            _ = try await firestoreService.createQuestWithPayment(
                quest: quest,
                requesterId: requesterId
            )
            isCompleted = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }
}
