import SwiftUI

@Observable
@MainActor
final class GigCollectionViewModel {

    // MARK: - Input (set once)
    let detail: ApplicationDetail

    // MARK: - Recording state
    var recordingPhase: RecordingPhase?
    var selectedLabel: ApplicationLabel?

    // MARK: - Sensor
    let sensorManager = SensorManager()

    init(detail: ApplicationDetail) {
        self.detail = detail
    }

    // MARK: - Actions

    /// Called when user taps Start on the "Begin <Label>" sheet
    func beginLabel(_ label: ApplicationLabel) {
        selectedLabel = label
        recordingPhase = .countdown
    }

    /// Called by CountdownOverlayView when countdown finishes
    func countdownFinished() {
        guard let label = selectedLabel else { return }
        sensorManager.startRecording(
            label: label,
            gigId: detail.id,
            gigTitle: detail.gigDetail.title,
            companyName: detail.gigDetail.companyName,
            assignmentCode: detail.assignmentCode ?? ""
        )
        recordingPhase = .recording
    }

    /// Called by LabelRecordingView when timer auto-completes (full duration). Shows summary.
    func stopRecording() {
        if let session = sensorManager.stopRecording() {
            recordingPhase = .summary(session)
        } else {
            recordingPhase = nil
        }
    }

    /// Called by LabelRecordingView "Stop Early" button or background during recording. Discards without showing summary.
    func stopEarlyAndDiscard() {
        sensorManager.stopRecording()
        recordingPhase = nil
    }

    /// Called by RecordingSummaryView after it has already saved the session.
    /// Only dismisses the cover — does NOT call save (the view handles save + error).
    func dismissAfterSave() {
        recordingPhase = nil
    }

    /// Called by RecordingSummaryView "Delete"
    func discardAndDismiss() {
        recordingPhase = nil
    }

    /// Called by CountdownOverlayView cancel or background during countdown
    func cancelCountdown() {
        recordingPhase = nil
    }
}
