import SwiftUI

struct RecordingSummaryView: View {
    let session: GigRecordingSession
    @Bindable var viewModel: GigCollectionViewModel
    @State private var showUploadAlert = false
    @State private var storageFull = false

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
                    statRow(label: "Label", value: session.labelName)
                    statRow(label: "Duration", value: formattedSeconds(actualDurationSeconds))
                    statRow(label: "Frames", value: "\(session.frames.count)")
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
                    viewModel.discardAndDismiss()
                } label: {
                    Label("Delete", systemImage: "trash")
                        .font(.subheadline).bold()
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .controlSize(.large)

                Spacer()

                Button {
                    showUploadAlert = true
                } label: {
                    Label("Submit", systemImage: "arrow.up.circle")
                        .font(.subheadline).bold()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.black)
        }
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
        let elapsed = Int(session.endTime.timeIntervalSince(session.startTime).rounded())
        return min(max(0, elapsed), session.intendedDurationSeconds)
    }

    private func formattedSeconds(_ seconds: Int) -> String {
        Duration.seconds(seconds).formatted(.time(pattern: .minuteSecond(padMinuteToLength: 1)))
    }
}
