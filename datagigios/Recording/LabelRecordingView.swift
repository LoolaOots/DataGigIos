import SwiftUI

struct LabelRecordingView: View {
    @Bindable var viewModel: GigCollectionViewModel
    @State private var elapsed: TimeInterval = 0
    @State private var timer: Timer?

    private var intended: Int { viewModel.selectedLabel?.durationSeconds ?? 1 }
    private var remaining: TimeInterval { max(0, TimeInterval(intended) - elapsed) }
    private var progress: Double { elapsed / TimeInterval(intended) }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Label name + REC badge
            if let label = viewModel.selectedLabel {
                Text(label.labelName)
                    .font(.title2).bold()
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                Text("REC")
                    .font(.caption).bold()
                    .foregroundStyle(.red)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.red.opacity(0.15), in: Capsule())

            // Circular timer
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 10)

                Circle()
                    .trim(from: 0, to: 1.0 - progress)
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: progress)

                Text(formattedTime(remaining))
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            .frame(width: 200, height: 200)

            Spacer()

            Button("Stop Early") {
                stopTimer()
                viewModel.stopRecording()
            }
            .buttonStyle(.bordered)
            .tint(.white)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }

    private func startTimer() {
        elapsed = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [self] _ in
            Task { @MainActor in
                elapsed += 0.5
                if elapsed >= TimeInterval(intended) {
                    stopTimer()
                    viewModel.stopRecording()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func formattedTime(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
