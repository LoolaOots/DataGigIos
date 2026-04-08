//
//  ApplicationsListView.swift
//  datagigios
//

import SwiftUI

struct ApplicationsListView: View {
    let accessToken: String

    @State private var viewModel = ApplicationsViewModel()
    @State private var selectedApplicationId: String?

    var body: some View {
        List {
            // Filter pills — always visible as first row
            FilterPills(viewModel: viewModel)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

            ForEach(viewModel.filteredApplications) { application in
                Button {
                    selectedApplicationId = application.id
                } label: {
                    ApplicationRowView(application: application)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("View \(application.gigTitle) application")
                .accessibilityHint("Status: \(statusLabel(for: application.status))")
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if viewModel.isLoading && viewModel.applications.isEmpty {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.error, viewModel.applications.isEmpty {
                ContentUnavailableView(
                    "Failed to Load",
                    systemImage: "exclamationmark.triangle.fill",
                    description: Text(errorMessage)
                )
            } else if viewModel.filteredApplications.isEmpty {
                ContentUnavailableView(
                    "No Applications",
                    systemImage: "doc.text",
                    description: Text(viewModel.filter == .all ? "You haven't applied to any gigs yet" : "No \(viewModel.filter.rawValue.lowercased()) applications")
                )
            }
        }
        .navigationTitle("My Applications")
        .navigationDestination(item: $selectedApplicationId) { id in
            ApplicationDetailView(applicationId: id, accessToken: accessToken)
        }
        .task {
            await viewModel.load(accessToken: accessToken)
        }
        .refreshable {
            await viewModel.load(accessToken: accessToken)
        }
        .sensoryFeedback(.selection, trigger: viewModel.filter) { old, new in
            old != new
        }
    }
}

// MARK: - FilterPills

private struct FilterPills: View {
    @Bindable var viewModel: ApplicationsViewModel

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(ApplicationFilter.allCases) { filter in
                    FilterPillButton(
                        title: filter.rawValue,
                        isSelected: viewModel.filter == filter
                    ) {
                        viewModel.filter = filter
                    }
                }
            }
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - FilterPillButton

private struct FilterPillButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .bold(isSelected)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary),
                    in: .capsule
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

private func statusLabel(for status: String) -> String {
    switch status {
    case "accepted": return "Active"
    case "pending": return "Pending"
    case "denied": return "Denied"
    default: return status.capitalized
    }
}

// MARK: - ApplicationRowView

struct ApplicationRowView: View {
    let application: Application

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(application.gigTitle)
                    .font(.headline)
                    .lineLimit(2)

                Spacer()

                ApplicationStatusBadge(status: application.status)
            }

            HStack(spacing: 8) {
                Label(deviceTypeLabel(application.deviceType), systemImage: deviceTypeIcon(application.deviceType))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(application.appliedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(.rect)
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

// MARK: - ApplicationStatusBadge

struct ApplicationStatusBadge: View {
    let status: String

    var body: some View {
        Text(statusLabel)
            .font(.caption)
            .bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.15), in: .capsule)
            .foregroundStyle(statusColor)
    }

    private var statusLabel: String {
        switch status {
        case "accepted": return "Active"
        case "pending": return "Pending"
        case "denied": return "Denied"
        default: return status.capitalized
        }
    }

    private var statusColor: Color {
        switch status {
        case "accepted": return .green
        case "pending": return .yellow
        case "denied": return .red
        default: return .secondary
        }
    }
}

#Preview {
    NavigationStack {
        ApplicationsListView(accessToken: "preview-token")
    }
}
