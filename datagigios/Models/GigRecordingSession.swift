import Foundation

struct GigRecordingSession: Identifiable, Codable, Equatable {
    let id: UUID
    let gigId: String
    let gigTitle: String
    let companyName: String         // may be empty string pre-backend-update
    let labelId: String
    let labelName: String
    let assignmentCode: String
    let startTime: Date
    let endTime: Date
    let intendedDurationSeconds: Int
    var frames: [SensorFrame]
    var isSubmitted: Bool = false
}
