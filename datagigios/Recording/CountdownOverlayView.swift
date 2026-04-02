import Combine
import SwiftUI

struct CountdownOverlayView: View {
    @Bindable var viewModel: GigCollectionViewModel
    @State private var count = 10

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Countdown number with green glow
            Text("\(count)")
                .font(.system(.largeTitle, design: .rounded).weight(.black))
                .scaleEffect(3.0)
                .foregroundStyle(.green)
                .shadow(color: .green.opacity(0.6), radius: 20)
                .frame(height: 160)

            if let label = viewModel.selectedLabel {
                VStack(spacing: 8) {
                    Text(label.labelName)
                        .font(.title2).bold()
                        .foregroundStyle(.white)
                    Text((Double(label.rateCents) / 100.0).formatted(.currency(code: "USD")))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button("Cancel", role: .destructive) {
                timer.upstream.connect().cancel()
                viewModel.cancelCountdown()
            }
            .buttonStyle(.bordered)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onReceive(timer) { _ in
            if count > 0 {
                count -= 1
            }
            if count == 0 {
                timer.upstream.connect().cancel()
                viewModel.countdownFinished()
            }
        }
    }
}
