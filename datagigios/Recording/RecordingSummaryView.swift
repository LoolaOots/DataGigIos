import SwiftUI

struct RecordingSummaryView: View {
    let session: GigRecordingSession
    let accessToken: String
    @Bindable var viewModel: GigCollectionViewModel
    @Environment(SubmissionService.self) private var submissionService
    @State private var submissionError: String? = nil
    @State private var showErrorAlert = false
    @State private var storageFull = false
    @State private var showDiscardConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            // Done button top right
            HStack {
                Spacer()
                Button("Done") {
                    do {
                        try GigRecordingSessionStore.save(session)
                        viewModel.dismissAfterSave()
                    } catch {
                        storageFull = true
                    }
                }
                .bold()
                .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Content pushed toward the top
            VStack(spacing: 0) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)

                Text("Recording Complete")
                    .font(.title2).bold()
                    .foregroundStyle(.white)
                    .padding(.top, 12)

                // Stats
                VStack(spacing: 12) {
                    StatRow(label: "Label", value: session.labelName)
                    StatRow(label: "Duration", value: formattedSeconds(actualDurationSeconds))
                    StatRow(label: "Frames", value: "\(session.frames.count)")
                }
                .padding()
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                .padding(.top, 24)
            }
            .padding(.top, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button(role: .destructive) {
                    showDiscardConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                        .font(.subheadline).bold()
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .controlSize(.large)

                Spacer()

                Button {
                    Task {
                        // Persist session to disk first so it survives a crash during upload
                        do {
                            try GigRecordingSessionStore.save(session)
                        } catch {
                            storageFull = true
                            return
                        }
                        do {
                            try await submissionService.submit(session: session, assignmentCode: viewModel.detail.assignmentCode ?? "", accessToken: accessToken)
                        } catch {
                            submissionError = error.localizedDescription
                            showErrorAlert = true
                        }
                    }
                } label: {
                    if submissionService.isSubmitting {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Label("Submit", systemImage: "arrow.up.circle")
                            .font(.subheadline).bold()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(submissionService.isSubmitting || submissionService.submittedSessionIds.contains(session.id))
                .alert("Upload Error", isPresented: $showErrorAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(submissionError ?? "An unknown error occurred.")
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.black)
        }
        .alert("Storage Full", isPresented: $storageFull) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Storage full — delete recordings to free space")
        }
        .alert("Discard Recording?", isPresented: $showDiscardConfirmation) {
            Button("Discard", role: .destructive) {
                viewModel.discardAndDismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private var actualDurationSeconds: Int {
        let elapsed = Int(session.endTime.timeIntervalSince(session.startTime).rounded())
        return min(max(0, elapsed), session.intendedDurationSeconds)
    }

    private func formattedSeconds(_ seconds: Int) -> String {
        Duration.seconds(seconds).formatted(.time(pattern: .minuteSecond(padMinuteToLength: 1)))
    }
}

// MARK: - StatRow

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).bold().foregroundStyle(.white)
        }
    }
}
