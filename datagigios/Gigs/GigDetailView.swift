//
//  GigDetailView.swift
//  datagigios
//

import SwiftUI

struct GigDetailView: View {
    let gigId: String
    let session: Session?
    let existingApplications: [Application]

    @State private var viewModel: GigDetailViewModel
    @State private var showAuth = false
    @State private var navigateToApply = false

    init(gigId: String, session: Session? = nil, existingApplications: [Application] = []) {
        self.gigId = gigId
        self.session = session
        self.existingApplications = existingApplications
        _viewModel = State(initialValue: GigDetailViewModel(
            gigId: gigId,
            session: session,
            existingApplications: existingApplications
        ))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.gig == nil {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.error != nil, viewModel.gig == nil {
                GigLoadErrorView {
                    Task { await viewModel.loadGig() }
                }
            } else {
                ScrollView {
                    if let gig = viewModel.gig {
                        VStack(alignment: .leading, spacing: 20) {
                            GigHeaderSection(gig: gig)

                            Divider()

                            GigDescriptionSection(description: gig.description)

                            Divider()

                            if gig.applicationDeadline != nil || gig.dataDeadline != nil {
                                GigDeadlinesSection(
                                    applicationDeadline: gig.applicationDeadline,
                                    dataDeadline: gig.dataDeadline
                                )
                                Divider()
                            }

                            GigDeviceTypesSection(deviceTypes: gig.deviceTypes)

                            Divider()

                            GigLabelsSection(labels: gig.labels)
                        }
                        .padding()
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    if let gig = viewModel.gig {
                        ApplyButton(
                            gig: gig,
                            viewModel: viewModel,
                            showAuth: $showAuth,
                            navigateToApply: $navigateToApply
                        )
                        .padding()
                        .background(.regularMaterial)
                    }
                }
            }
        }
        .navigationTitle(viewModel.gig?.title ?? "Gig Detail")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadGig()
        }
        .sheet(isPresented: $showAuth) {
            AuthView()
        }
        .navigationDestination(isPresented: $navigateToApply) {
            // Both conditions are always true here: ApplyButton only sets navigateToApply = true
            // when applyState == .canApply, which requires session != nil and gig != nil.
            if let gig = viewModel.gig, let session {
                ApplyView(gig: gig, session: session)
            }
        }
    }
}

// MARK: - ApplyButton

private struct ApplyButton: View {
    let gig: GigDetail
    @Bindable var viewModel: GigDetailViewModel
    @Binding var showAuth: Bool
    @Binding var navigateToApply: Bool

    var body: some View {
        switch viewModel.applyState {
        case .signInRequired:
            Button("Sign in to Apply") {
                showAuth = true
            }
            .buttonStyle(.primary)

        case .canApply:
            Button("Apply to Gig") {
                navigateToApply = true
            }
            .buttonStyle(.primary)

        case .applied:
            Button("Applied") {}
                .buttonStyle(.successPrimary)
                .disabled(true)
                .accessibilityLabel("Already applied")
        }
    }
}

// MARK: - GigHeaderSection

private struct GigHeaderSection: View {
    let gig: GigDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(gig.title)
                .font(.title2)
                .bold()

            Text(gig.companyName)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Label(
                    gig.activityType.replacing("_", with: " ").capitalized,
                    systemImage: "figure.run"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Spacer()

                Text(payoutRangeString(minCents: gig.minRateCents, maxCents: gig.maxRateCents))
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(.green)
            }

            HStack(spacing: 8) {
                Text("\(gig.filledSlots) / \(gig.totalSlots) slots filled")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                StatusBadge(status: gig.status)
            }
        }
    }

}

// MARK: - GigDescriptionSection

private struct GigDescriptionSection: View {
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About this Gig")
                .font(.headline)
            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - GigDeadlinesSection

private struct GigDeadlinesSection: View {
    let applicationDeadline: Date?
    let dataDeadline: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Deadlines")
                .font(.headline)
            if let deadline = applicationDeadline {
                Label(
                    "Apply by: \(deadline.formatted(date: .abbreviated, time: .omitted))",
                    systemImage: "calendar.badge.clock"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            if let deadline = dataDeadline {
                Label(
                    "Data due: \(deadline.formatted(date: .abbreviated, time: .omitted))",
                    systemImage: "calendar.badge.checkmark"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - GigDeviceTypesSection

private struct GigDeviceTypesSection: View {
    let deviceTypes: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Required Devices")
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(deviceTypes, id: \.self) { deviceType in
                    Label(deviceTypeLabel(deviceType), systemImage: deviceTypeIcon(deviceType))
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.tint.opacity(0.12), in: .capsule)
                        .foregroundStyle(.tint)
                }
            }
        }
    }

    private func deviceTypeIcon(_ type: String) -> String {
        switch type {
        case "apple_watch": return "applewatch"
        case "generic_android": return "iphone.gen1"
        default: return "iphone"
        }
    }

    private func deviceTypeLabel(_ type: String) -> String {
        switch type {
        case "apple_watch": return "Apple Watch"
        case "generic_android": return "Android"
        default: return "iPhone"
        }
    }
}

// MARK: - GigLabelsSection

private struct GigLabelsSection: View {
    let labels: [GigLabel]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Labels")
                .font(.headline)

            ForEach(labels) { label in
                GigLabelRow(label: label)
            }
        }
    }
}

// MARK: - GigLabelRow

private struct GigLabelRow: View {
    let label: GigLabel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.labelName)
                .font(.subheadline)
                .bold()

            HStack {
                Label(formattedDuration(label.durationSeconds), systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text((Double(label.rateCents) / 100).formatted(.currency(code: "USD")))
                    .font(.caption)
                    .bold()
                    .foregroundStyle(.green)
            }

            if let description = label.description {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 12))
    }

    private func formattedDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        if minutes > 0 && remainingSeconds > 0 {
            return "\(minutes) min \(remainingSeconds) sec"
        } else if minutes > 0 {
            return "\(minutes) min"
        } else {
            return "\(remainingSeconds) sec"
        }
    }
}

// MARK: - StatusBadge

private struct StatusBadge: View {
    let status: String

    var body: some View {
        Text(status.capitalized)
            .font(.caption)
            .bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.15), in: .capsule)
            .foregroundStyle(statusColor)
    }

    private var statusColor: Color {
        switch status {
        case "open": return .green
        case "paused": return .orange
        case "completed", "cancelled": return .red
        default: return .secondary
        }
    }
}

// MARK: - GigLoadErrorView

private struct GigLoadErrorView: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .imageScale(.large)
                .foregroundStyle(.orange)

            VStack(spacing: 8) {
                Text("Unable to Load Gig")
                    .font(.title2)
                    .bold()

                Text("Please try again later.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("Retry", action: onRetry)
                .buttonStyle(.primary)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    NavigationStack {
        GigDetailView(gigId: "preview-id")
    }
    .environment(AuthRouter())
}
