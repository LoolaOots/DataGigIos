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

    /// Called by LabelRecordingView on Stop Early, auto-end, or background
    func stopRecording() {
        if let session = sensorManager.stopRecording() {
            recordingPhase = .summary(session)
        } else {
            recordingPhase = nil
        }
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
