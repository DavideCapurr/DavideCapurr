import Foundation
import FirebaseFirestore

enum SubmissionStatus: String, Codable {
    case pending
    case approved
    case rejected
}

enum MediaType: String, Codable {
    case photo
    case video
}

struct Submission: Identifiable, Codable {
    @DocumentID var id: String?
    let questId: String
    let earnerId: String
    let requesterId: String
    let mediaType: MediaType
    let mediaUrl: String
    var thumbnailUrl: String?
    var note: String?
    var status: SubmissionStatus
    let createdAt: Date
    var reviewedAt: Date?

    init(
        id: String? = nil,
        questId: String,
        earnerId: String,
        requesterId: String,
        mediaType: MediaType,
        mediaUrl: String,
        thumbnailUrl: String? = nil,
        note: String? = nil,
        status: SubmissionStatus = .pending,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.questId = questId
        self.earnerId = earnerId
        self.requesterId = requesterId
        self.mediaType = mediaType
        self.mediaUrl = mediaUrl
        self.thumbnailUrl = thumbnailUrl
        self.note = note
        self.status = status
        self.createdAt = createdAt
    }
}
