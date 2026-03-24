import Foundation

struct SensorFrame: Codable, Equatable {
    let timestamp: Date
    let labelName: String
    let pitch: Double?
    let roll: Double?
    let yaw: Double?
    let latitude: Double?
    let longitude: Double?
    let relativeAltitude: Double?
    let absoluteAltitude: Double?
    let pressure: Double?           // kPa
    let trueHeading: Double?        // degrees 0–360; nil if unavailable
    let speed: Double?              // m/s
    let accelX: Double?
    let accelY: Double?
    let accelZ: Double?
    let gForceX: Double?
    let gForceY: Double?
    let gForceZ: Double?
    let gravityX: Double?
    let gravityY: Double?
    let gravityZ: Double?
    let gyroX: Double?              // degrees/sec
    let gyroY: Double?
    let gyroZ: Double?
    let magX: Double?               // µT
    let magY: Double?
    let magZ: Double?
    let cadence: Double?            // steps/sec
}
