import Foundation
import PhotosUI
import SwiftUI

@MainActor
final class SubmissionViewModel: ObservableObject {
    @Published var selectedImageData: Data?
    @Published var selectedVideoData: Data?
    @Published var note = ""
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    @Published var errorMessage: String?
    @Published var isCompleted = false

    let quest: Quest

    private let storageService = StorageService.shared
    private let firestoreService = FirestoreService.shared

    init(quest: Quest) {
        self.quest = quest
    }

    var hasMedia: Bool {
        selectedImageData != nil || selectedVideoData != nil
    }

    var mediaType: MediaType {
        selectedVideoData != nil ? .video : .photo
    }

    func submit(earnerId: String) async {
        guard let questId = quest.id else { return }

        let data: Data
        let type: MediaType

        if let videoData = selectedVideoData {
            data = videoData
            type = .video
        } else if let imageData = selectedImageData {
            data = imageData
            type = .photo
        } else {
            errorMessage = "Please capture a photo or video"
            return
        }

        isUploading = true
        errorMessage = nil

        do {
            let mediaUrl = try await storageService.uploadQuestSubmission(
                questId: questId,
                earnerId: earnerId,
                data: data,
                mediaType: type
            )

            let submission = Submission(
                questId: questId,
                earnerId: earnerId,
                requesterId: quest.requesterId,
                mediaType: type,
                mediaUrl: mediaUrl,
                note: note.isEmpty ? nil : note
            )

            _ = try await firestoreService.createSubmission(submission)

            try await firestoreService.updateQuestStatus(
                questId: questId,
                status: .submitted,
                extraFields: ["submittedAt": Date()]
            )

            isCompleted = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isUploading = false
    }
}
