import SwiftUI

struct LabelRecordingView: View {
    @Bindable var viewModel: GigCollectionViewModel
    @State private var timeRemaining: Int = 0
    @State private var timer: Timer?

    private var intended: Int { viewModel.selectedLabel?.durationSeconds ?? 1 }
    private var progress: Double {
        guard intended > 0 else { return 0 }
        return 1.0 - Double(timeRemaining) / Double(intended)
    }

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
                    .animation(.linear(duration: 1.0), value: progress)

                Text(formattedTime(timeRemaining))
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            .frame(width: 200, height: 200)

            Spacer()

            Button("Stop Early") {
                stopTimer()
                viewModel.stopEarlyAndDiscard()
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
        timeRemaining = intended
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] _ in
            Task { @MainActor in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                }
                if timeRemaining == 0 {
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

    private func formattedTime(_ seconds: Int) -> String {
        Duration.seconds(seconds).formatted(.time(pattern: .minuteSecond(padMinuteToLength: 1)))
    }
}
