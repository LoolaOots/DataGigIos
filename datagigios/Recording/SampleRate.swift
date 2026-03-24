import Foundation

enum SampleRate {
    case standard  // 10 Hz — walking, slow activities
    case high      // 50 Hz — jumping, trotting, dynamic activities

    var interval: TimeInterval {
        switch self {
        case .standard: return 1.0 / 10.0
        case .high:     return 1.0 / 50.0
        }
    }
}
