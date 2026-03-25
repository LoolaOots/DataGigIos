import Foundation

enum GigRecordingSessionStore {

    private static var baseURL: URL {
        URL.documentsDirectory.appending(path: "GigRecordings")
    }

    private static func folder(assignmentCode: String, labelId: String) -> URL {
        baseURL
            .appending(path: assignmentCode)
            .appending(path: labelId)
    }

    static func save(_ session: GigRecordingSession) throws {
        let dir = folder(assignmentCode: session.assignmentCode, labelId: session.labelId)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let fileURL = dir.appending(path: "\(session.id.uuidString).json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(session)
        try data.write(to: fileURL, options: .atomic)
    }

    static func loadAll(assignmentCode: String, labelId: String) -> [GigRecordingSession] {
        let dir = folder(assignmentCode: assignmentCode, labelId: labelId)
        guard let urls = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return urls
            .filter { $0.pathExtension == "json" }
            .compactMap { try? decoder.decode(GigRecordingSession.self, from: Data(contentsOf: $0)) }
    }

    static func loadAllForGig(assignmentCode: String) -> [GigRecordingSession] {
        let gigDir = baseURL.appending(path: assignmentCode)
        guard let labelDirs = try? FileManager.default.contentsOfDirectory(at: gigDir, includingPropertiesForKeys: nil) else { return [] }
        return labelDirs.flatMap { loadAll(assignmentCode: assignmentCode, labelId: $0.lastPathComponent) }
    }

    static func delete(id: UUID, assignmentCode: String, labelId: String) throws {
        let fileURL = folder(assignmentCode: assignmentCode, labelId: labelId)
            .appending(path: "\(id.uuidString).json")
        try FileManager.default.removeItem(at: fileURL)
    }
}
