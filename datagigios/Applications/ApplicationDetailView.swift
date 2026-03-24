//
//  ApplicationDetailView.swift
//  datagigios
//

import SwiftUI

struct ApplicationDetailView: View {
    let applicationId: String
    let accessToken: String

    @State private var viewModel = ApplicationsViewModel()
    @State private var permissionsManager = PermissionsManager()
    @State private var showCollection = false
    @State private var showPermissionsDenied = false

    var body: some View {
        Group {
            if viewModel.isLoadingDetail && viewModel.selectedDetail == nil {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.error, viewModel.selectedDetail == nil {
                ContentUnavailableView(
                    "Failed to Load",
                    systemImage: "exclamationmark.triangle.fill",
                    description: Text(errorMessage)
                )
            } else if let detail = viewModel.selectedDetail {
                detailContent(detail: detail)
            }
        }
        .navigationTitle(viewModel.selectedDetail?.gigTitle ?? "Application")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadDetail(applicationId: applicationId, accessToken: accessToken)
        }
        .navigationDestination(isPresented: $showCollection) {
            if let detail = viewModel.selectedDetail {
                GigCollectionView(viewModel: GigCollectionViewModel(detail: detail))
            }
        }
        .navigationDestination(isPresented: $showPermissionsDenied) {
            PermissionsDeniedView(
                onGranted: {
                    showPermissionsDenied = false
                    showCollection = true
                },
                onBack: {
                    showPermissionsDenied = false
                }
            )
        }
    }

    // MARK: - Detail content

    private func detailContent(detail: ApplicationDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Status banner
                StatusBannerView(status: detail.status)

                // Assignment code card
                if let code = detail.assignmentCode {
                    AssignmentCodeCard(
                        code: code,
                        dataDeadline: detail.gigDetail.dataDeadline
                    )
                }

                Divider()

                // Gig info
                GigInfoSection(gigDetail: detail.gigDetail)

                Divider()

                // Labels
                LabelsSection(labels: detail.gigDetail.labels)

                // Company note
                if let note = detail.noteFromCompany {
                    Divider()
                    NoteSection(title: "Note from Company", note: note, icon: "building.2")
                }

                // User note
                if let note = detail.noteFromUser {
                    Divider()
                    NoteSection(title: "Your Note", note: note, icon: "person")
                }

                if detail.status == "accepted" {
                    VStack(spacing: 12) {
                        Button {
                            permissionsManager.check { result in
                                switch result {
                                case .granted: showCollection = true
                                case .denied:  showPermissionsDenied = true
                                }
                            }
                        } label: {
                            Label("Start Collecting Data", systemImage: "record.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        NavigationLink(destination: GigRecordingsLibraryView(
                            assignmentCode: detail.assignmentCode ?? "",
                            gigTitle: detail.gigDetail.title,
                            companyName: detail.gigDetail.companyName
                        )) {
                            Label("View Recordings", systemImage: "list.bullet.rectangle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                }
            }
            .padding()
        }
    }
}

// MARK: - StatusBannerView

private struct StatusBannerView: View {
    let status: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon)
                .font(.title2)
                .foregroundStyle(statusColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(statusTitle)
                    .font(.headline)
                    .foregroundStyle(statusColor)
                Text(statusDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(statusColor.opacity(0.1), in: .rect(cornerRadius: 14))
    }

    private var statusIcon: String {
        switch status {
        case "accepted": return "checkmark.circle.fill"
        case "pending": return "clock.fill"
        case "denied": return "xmark.circle.fill"
        default: return "questionmark.circle.fill"
        }
    }

    private var statusTitle: String {
        switch status {
        case "accepted": return "Accepted"
        case "pending": return "Pending Review"
        case "denied": return "Not Selected"
        default: return status.capitalized
        }
    }

    private var statusDescription: String {
        switch status {
        case "accepted": return "Your application was accepted. Use your assignment code to submit."
        case "pending": return "Your application is being reviewed."
        case "denied": return "Unfortunately your application was not selected for this gig."
        default: return ""
        }
    }

    private var statusColor: Color {
        switch status {
        case "accepted": return .green
        case "pending": return .orange
        case "denied": return .red
        default: return .secondary
        }
    }
}

// MARK: - AssignmentCodeCard

private struct AssignmentCodeCard: View {
    let code: String
    let dataDeadline: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Assignment Code")
                .font(.headline)

            Text(code)
                .font(.system(.largeTitle, design: .monospaced))
                .bold()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical)

            Text("Use this code when submitting recordings")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)

            if let deadline = dataDeadline {
                Divider()
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(.orange)
                    Text("Data deadline: \(deadline.formatted(date: .long, time: .omitted))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
    }
}

// MARK: - GigInfoSection

private struct GigInfoSection: View {
    let gigDetail: ApplicationGigDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gig Details")
                .font(.headline)

            Text(gigDetail.title)
                .font(.subheadline)
                .bold()

            Label(
                gigDetail.activityType.replacing("_", with: " ").capitalized,
                systemImage: "figure.run"
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Text(gigDetail.description)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - LabelsSection

private struct LabelsSection: View {
    let labels: [ApplicationLabel]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Labels")
                .font(.headline)

            ForEach(labels) { label in
                ApplicationLabelRow(label: label)
            }
        }
    }
}

// MARK: - ApplicationLabelRow

private struct ApplicationLabelRow: View {
    let label: ApplicationLabel

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

// MARK: - NoteSection

private struct NoteSection: View {
    let title: String
    let note: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)

            Text(note)
                .font(.body)
                .foregroundStyle(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 12))
        }
    }
}

#Preview {
    NavigationStack {
        ApplicationDetailView(applicationId: "preview-id", accessToken: "preview-token")
    }
}
