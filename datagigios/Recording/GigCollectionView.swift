import SwiftUI

struct GigCollectionView: View {
    @Bindable var viewModel: GigCollectionViewModel
    @State private var showBeginSheet = false

    var body: some View {
        VStack(spacing: 0) {
            labelList
        }
        .navigationTitle("\(viewModel.detail.gigDetail.title) - \(viewModel.detail.gigDetail.companyName)")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBeginSheet) {
            if let label = viewModel.selectedLabel {
                beginSheet(label: label)
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { viewModel.recordingPhase != nil },
            set: { if !$0 { viewModel.recordingPhase = nil } }
        )) {
            RecordingCoordinatorView(viewModel: viewModel)
        }
    }

    private var labelList: some View {
        List {
            ForEach(viewModel.detail.gigDetail.labels) { label in
                Button {
                    viewModel.selectedLabel = label
                    showBeginSheet = true
                } label: {
                    labelRow(label: label)
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }

            Text("Tap any label to begin")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }

    private func labelRow(label: ApplicationLabel) -> some View {
        HStack(spacing: 0) {
            // Green accent bar
            Rectangle()
                .fill(Color.green)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(label.labelName)
                    .font(.title3).bold()
                HStack(spacing: 14) {
                    Label(formattedDuration(label.durationSeconds), systemImage: "timer")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Label(formattedRate(label.rateCents), systemImage: "dollarsign.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let description = label.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.leading, 12)
            .padding(.vertical, 14)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.trailing, 16)
        }
        .padding(.leading, 0)
    }

    @ViewBuilder
    private func beginSheet(label: ApplicationLabel) -> some View {
        VStack(spacing: 24) {
            Text("Begin \(label.labelName)")
                .font(.title2).bold()
                .multilineTextAlignment(.center)
                .padding(.top, 24)
                .padding(.horizontal)

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Duration", systemImage: "stopwatch")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(formattedDuration(label.durationSeconds))
                        .font(.title3).bold()
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Label("Expected Payout", systemImage: "dollarsign.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(formattedRate(label.rateCents))
                        .font(.title3).bold()
                        .foregroundStyle(.green)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            VStack(spacing: 12) {
                Button("Start") {
                    showBeginSheet = false
                    viewModel.beginLabel(label)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)

                Button("Cancel") {
                    showBeginSheet = false
                    viewModel.selectedLabel = nil
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
            }

            Spacer()
        }
        .presentationDetents([.medium])
    }

    // MARK: - Helpers

    private func formattedDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return s == 0 ? "\(m)m" : "\(m)m \(s)s"
    }

    private func formattedRate(_ cents: Int) -> String {
        return (Double(cents) / 100.0).formatted(.currency(code: "USD"))
    }
}

// MARK: - RecordingCoordinator

private struct RecordingCoordinatorView: View {
    @Bindable var viewModel: GigCollectionViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            switch viewModel.recordingPhase {
            case .countdown:
                CountdownOverlayView(viewModel: viewModel)
            case .recording:
                LabelRecordingView(viewModel: viewModel)
            case .summary(let session):
                RecordingSummaryView(session: session, viewModel: viewModel)
            case nil:
                EmptyView()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .background else { return }
            switch viewModel.recordingPhase {
            case .countdown:
                viewModel.cancelCountdown()
            case .recording:
                viewModel.stopRecording()
            default:
                break
            }
        }
    }
}
