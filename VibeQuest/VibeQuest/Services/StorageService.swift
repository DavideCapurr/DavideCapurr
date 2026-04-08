import Foundation
import FirebaseStorage

final class StorageService {
    static let shared = StorageService()
    private let storage = Storage.storage()

    private init() {}

    func uploadMedia(data: Data, path: String, contentType: String) async throws -> String {
        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = contentType

        _ = try await ref.putDataAsync(data, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }

    func uploadQuestSubmission(
        questId: String,
        earnerId: String,
        data: Data,
        mediaType: MediaType
    ) async throws -> String {
        let ext = mediaType == .photo ? "jpg" : "mp4"
        let contentType = mediaType == .photo ? "image/jpeg" : "video/mp4"
        let path = "submissions/\(questId)/\(earnerId)_\(Int(Date().timeIntervalSince1970)).\(ext)"

        return try await uploadMedia(data: data, path: path, contentType: contentType)
    }
}
