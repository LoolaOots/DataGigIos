// datagigios/Submissions/SensorDataExporter.swift
import Foundation

struct SensorDataExporter {
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static func export(session: GigRecordingSession) -> Data {
        var lines: [String] = []

        // Header — 27 columns
        lines.append(
            "timestamp,label_name," +
            "pitch,roll,yaw," +
            "latitude,longitude,altitude," +
            "pressure,heading,speed," +
            "accel_x,accel_y,accel_z," +
            "gforce_x,gforce_y,gforce_z," +
            "gravity_x,gravity_y,gravity_z," +
            "gyro_x,gyro_y,gyro_z," +
            "mag_x,mag_y,mag_z," +
            "cadence"
        )

        // Data rows — labelName comes from the session, not from each frame
        for frame in session.frames {
            let ts = iso8601Formatter.string(from: frame.timestamp)
            let row = [
                ts,
                session.labelName,              // session-level field, same for every row
                fmt(frame.pitch),
                fmt(frame.roll),
                fmt(frame.yaw),
                fmt(frame.latitude),
                fmt(frame.longitude),
                fmt(frame.relativeAltitude),    // altitude = relativeAltitude
                fmt(frame.pressure),
                fmt(frame.trueHeading),
                fmt(frame.speed),
                fmt(frame.accelX),
                fmt(frame.accelY),
                fmt(frame.accelZ),
                fmt(frame.gForceX),
                fmt(frame.gForceY),
                fmt(frame.gForceZ),
                fmt(frame.gravityX),
                fmt(frame.gravityY),
                fmt(frame.gravityZ),
                fmt(frame.gyroX),
                fmt(frame.gyroY),
                fmt(frame.gyroZ),
                fmt(frame.magX),
                fmt(frame.magY),
                fmt(frame.magZ),
                fmt(frame.cadence),
            ].joined(separator: ",")
            lines.append(row)
        }

        let csv = lines.joined(separator: "\n")
        return Data(csv.utf8)
    }

    private static func fmt(_ value: Double?) -> String {
        guard let v = value else { return "" }
        return String(v)
    }
}
