import Foundation

enum RecordingPhase: Equatable {
    case countdown
    case recording
    case summary(GigRecordingSession)
}
