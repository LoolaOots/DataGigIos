import Foundation

@Observable
@MainActor
final class GigRecordingsLibraryViewModel {
    let assignmentCode: String
    let gigTitle: String
    let companyName: String

    var sessions: [GigRecordingSession] = []
    var isSelectMode = false
    var selectedIDs: Set<UUID> = []

    init(assignmentCode: String, gigTitle: String, companyName: String) {
        self.assignmentCode = assignmentCode
        self.gigTitle = gigTitle
        self.companyName = companyName
    }

    func load() {
        sessions = GigRecordingSessionStore.loadAllForGig(assignmentCode: assignmentCode)
            .sorted { $0.startTime > $1.startTime }
    }

    func delete(session: GigRecordingSession) {
        try? GigRecordingSessionStore.delete(id: session.id, assignmentCode: session.assignmentCode, labelId: session.labelId)
        sessions.removeAll { $0.id == session.id }
    }

    func deleteSelected() {
        for id in selectedIDs {
            if let session = sessions.first(where: { $0.id == id }) {
                try? GigRecordingSessionStore.delete(id: id, assignmentCode: session.assignmentCode, labelId: session.labelId)
            }
        }
        sessions.removeAll { selectedIDs.contains($0.id) }
        selectedIDs = []
        isSelectMode = false
    }

    func toggleSelect(_ id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    func selectAll() {
        selectedIDs = Set(sessions.map(\.id))
    }

    func clearSelection() {
        selectedIDs = []
        isSelectMode = false
    }
}
