import SwiftUI

struct GigCollectionView: View {
    @Bindable var viewModel: GigCollectionViewModel
    @State private var showBeginSheet = false
    @State private var pendingStart = false

    var body: some View {
        VStack(spacing: 0) {
            LabelListView(viewModel: viewModel, showBeginSheet: $showBeginSheet)
        }
        .navigationTitle("\(viewModel.detail.gigDetail.title) - \(viewModel.detail.gigDetail.companyName)")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBeginSheet, onDismiss: {
            if pendingStart {
                pendingStart = false
                viewModel.recordingPhase = .countdown
            } else {
                // Dismissed by Cancel or swipe — clear the selection
                viewModel.selectedLabel = nil
            }
        }) {
            if let label = viewModel.selectedLabel {
                BeginSheetView(
                    viewModel: viewModel,
                    label: label,
                    showBeginSheet: $showBeginSheet,
                    pendingStart: $pendingStart
                )
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { viewModel.recordingPhase != nil },
            set: { if !$0 { viewModel.recordingPhase = nil } }
        )) {
            RecordingCoordinatorView(viewModel: viewModel)
        }
    }
}

// MARK: - Shared Formatters

private func formattedDuration(_ seconds: Int) -> String {
    let m = seconds / 60
    let s = seconds % 60
    return s == 0 ? "\(m)m" : "\(m)m \(s)s"
}

private func formattedRate(_ cents: Int) -> String {
    (Double(cents) / 100.0).formatted(.currency(code: "USD"))
}

// MARK: - Label List

private struct LabelListView: View {
    @Bindable var viewModel: GigCollectionViewModel
    @Binding var showBeginSheet: Bool

    var body: some View {
        List {
            ForEach(viewModel.detail.gigDetail.labels) { label in
                Button {
                    viewModel.selectedLabel = label
                    showBeginSheet = true
                } label: {
                    LabelRowView(label: label)
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .accessibilityLabel("Begin \(label.labelName)")
                .accessibilityHint("Opens setup sheet to start recording")
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
}

// MARK: - Label Row

private struct LabelRowView: View {
    let label: ApplicationLabel

    var body: some View {
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
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Begin Sheet

private struct BeginSheetView: View {
    @Bindable var viewModel: GigCollectionViewModel
    let label: ApplicationLabel
    @Binding var showBeginSheet: Bool
    @Binding var pendingStart: Bool

    var body: some View {
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

            Spacer()

            VStack(spacing: 12) {
                Button {
                    pendingStart = true
                    showBeginSheet = false
                } label: {
                    Text("Start")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button(role: .destructive) {
                    showBeginSheet = false
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .presentationDetents([.medium])
    }
}

// MARK: - RecordingCoordinator

private struct RecordingCoordinatorView: View {
    @Bindable var viewModel: GigCollectionViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var recordingStarted = false
    @State private var recordingStopped = false

    var body: some View {
        RecordingPhaseView(viewModel: viewModel)
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
            .onChange(of: viewModel.recordingPhase) { old, new in
                if new == .recording { recordingStarted.toggle() }
                if old == .recording && new != .recording { recordingStopped.toggle() }
            }
            .sensoryFeedback(.start, trigger: recordingStarted)
            .sensoryFeedback(.stop, trigger: recordingStopped)
    }
}

private struct RecordingPhaseView: View {
    @Bindable var viewModel: GigCollectionViewModel

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
    }
}
