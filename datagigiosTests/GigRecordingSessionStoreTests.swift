import XCTest
@testable import datagigios

final class GigRecordingSessionStoreTests: XCTestCase {

    private func makeSession(assignmentCode: String = "ABC123", labelId: String = "label-1") -> GigRecordingSession {
        GigRecordingSession(
            id: UUID(),
            gigId: "gig-1",
            gigTitle: "Horse Riding",
            companyName: "CorpTest",
            labelId: labelId,
            labelName: "Walking",
            assignmentCode: assignmentCode,
            startTime: Date(),
            endTime: Date(),
            intendedDurationSeconds: 120,
            frames: []
        )
    }

    func testSaveAndLoadByLabel() throws {
        let session = makeSession()
        try GigRecordingSessionStore.save(session)
        let loaded = GigRecordingSessionStore.loadAll(assignmentCode: session.assignmentCode, labelId: session.labelId)
        XCTAssertTrue(loaded.contains { $0.id == session.id })
        // Cleanup
        try GigRecordingSessionStore.delete(id: session.id, assignmentCode: session.assignmentCode, labelId: session.labelId)
    }

    func testLoadAllForGig() throws {
        let s1 = makeSession(labelId: "label-1")
        let s2 = makeSession(labelId: "label-2")
        try GigRecordingSessionStore.save(s1)
        try GigRecordingSessionStore.save(s2)
        let all = GigRecordingSessionStore.loadAllForGig(assignmentCode: s1.assignmentCode)
        XCTAssertTrue(all.contains { $0.id == s1.id })
        XCTAssertTrue(all.contains { $0.id == s2.id })
        try GigRecordingSessionStore.delete(id: s1.id, assignmentCode: s1.assignmentCode, labelId: s1.labelId)
        try GigRecordingSessionStore.delete(id: s2.id, assignmentCode: s2.assignmentCode, labelId: s2.labelId)
    }

    func testDeleteRemovesFile() throws {
        let session = makeSession()
        try GigRecordingSessionStore.save(session)
        try GigRecordingSessionStore.delete(id: session.id, assignmentCode: session.assignmentCode, labelId: session.labelId)
        let loaded = GigRecordingSessionStore.loadAll(assignmentCode: session.assignmentCode, labelId: session.labelId)
        XCTAssertFalse(loaded.contains { $0.id == session.id })
    }

    func testIsSubmittedRoundTrips() throws {
        // Verify that isSubmitted persists correctly through save/load.
        // This guards against the checkmark-disappearing-after-restart bug.
        var session = makeSession()
        XCTAssertFalse(session.isSubmitted, "default should be false")
        try GigRecordingSessionStore.save(session)

        // Mark submitted and overwrite the saved file
        session.isSubmitted = true
        try GigRecordingSessionStore.save(session)

        let loaded = GigRecordingSessionStore.loadAll(assignmentCode: session.assignmentCode, labelId: session.labelId)
        let found = try XCTUnwrap(loaded.first { $0.id == session.id })
        XCTAssertTrue(found.isSubmitted, "isSubmitted should survive a save/load round-trip")

        try GigRecordingSessionStore.delete(id: session.id, assignmentCode: session.assignmentCode, labelId: session.labelId)
    }
}
