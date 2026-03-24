import SwiftUI

struct RecordingSummaryView: View {
    let session: GigRecordingSession
    @Bindable var viewModel: GigCollectionViewModel
    @State private var showUploadAlert = false
    @State private var storageFull = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("Recording Complete")
                .font(.title2).bold()
                .foregroundStyle(.white)

            // Stats
            VStack(spacing: 12) {
                statRow(label: "Label", value: session.labelName)
                statRow(label: "Duration", value: formattedSeconds(actualDurationSeconds))
                statRow(label: "Frames", value: "\(session.frames.count)")
                statRow(label: "Intended", value: "of \(formattedSeconds(session.intendedDurationSeconds)) total")
            }
            .padding()
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                Button("Done") {
                    do {
                        try GigRecordingSessionStore.save(session)
                        viewModel.dismissAfterSave()
                    } catch {
                        storageFull = true
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Submit") {
                    showUploadAlert = true
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button("Delete") {
                    viewModel.discardAndDismiss()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .alert("Upload Coming Soon", isPresented: $showUploadAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Uploading recordings will be available in a future update.")
        }
        .alert("Storage Full", isPresented: $storageFull) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Storage full — delete recordings to free space")
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).bold().foregroundStyle(.white)
        }
    }

    private var actualDurationSeconds: Int {
        guard let first = session.frames.first?.timestamp,
              let last = session.frames.last?.timestamp else { return 0 }
        return max(0, Int(last.timeIntervalSince(first)))
    }

    private func formattedSeconds(_ seconds: Int) -> String {
        Duration.seconds(seconds).formatted(.time(pattern: .minuteSecond(padMinuteToLength: 1)))
    }
}
