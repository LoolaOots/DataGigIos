//
//  DashboardView.swift
//  datagigios
//

import SwiftUI

// MARK: - AppDestination

enum AppDestination: Hashable {
    case gigList
    case gigDetail(String)
    case applyToGig(String)
    case applicationsList
    case applicationDetail(String)
    case currentGigs
}

// MARK: - DashboardView

struct DashboardView: View {
    @Environment(AuthRouter.self) private var authRouter
    @State private var viewModel = DashboardViewModel()
    @State private var submissionService = SubmissionService()
    @State private var path = NavigationPath()
    @State private var showSignOutConfirmation = false
    @State private var signOutConfirmed = false

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if viewModel.isLoading && viewModel.profile == nil {
                    ProgressView("Loading…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.error != nil, viewModel.profile == nil {
                    ContentUnavailableView {
                        Label("Unable to Load Dashboard", systemImage: "exclamationmark.triangle.fill")
                    } description: {
                        Text("Please try again later.")
                    } actions: {
                        Button("Retry") {
                            guard let token = authRouter.session?.accessToken else { return }
                            viewModel.isLoading = true
                            viewModel.error = nil
                            Task { await viewModel.load(accessToken: token) }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    DashboardContent(viewModel: viewModel, path: $path)
                }
            }
            .navigationTitle("DataGigs")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sign Out", role: .destructive) {
                        showSignOutConfirmation = true
                    }
                }
            }
            .navigationDestination(for: AppDestination.self) { destination in
                switch destination {
                case .gigList:
                    GigListView()
                case .gigDetail(let id):
                    GigDetailView(gigId: id, session: authRouter.session, existingApplications: viewModel.applications)
                case .applyToGig:
                    // ApplyView is pushed from GigDetailView via its own sheet/push
                    EmptyView()
                case .applicationsList:
                    ApplicationsListView(accessToken: authRouter.session?.accessToken ?? "")
                case .applicationDetail(let id):
                    ApplicationDetailView(applicationId: id, accessToken: authRouter.session?.accessToken ?? "")
                case .currentGigs:
                    CurrentGigsView(
                        viewModel: viewModel,
                        accessToken: authRouter.session?.accessToken ?? ""
                    )
                }
            }
            .navigationDestination(for: NavDestination.self) { destination in
                switch destination {
                case .gigList:
                    GigListView()
                case .gigDetail(let id):
                    GigDetailView(gigId: id, session: authRouter.session, existingApplications: viewModel.applications)
                }
            }
            .task {
                if let token = authRouter.session?.accessToken {
                    await viewModel.load(accessToken: token)
                }
            }
            .refreshable {
                if let token = authRouter.session?.accessToken {
                    await viewModel.load(accessToken: token)
                }
            }
            .alert("Sign Out?", isPresented: $showSignOutConfirmation) {
                Button("Sign Out", role: .destructive) {
                    signOutConfirmed.toggle()
                    authRouter.clearSession()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You will need to sign in again to access your account.")
            }
            .sensoryFeedback(.impact, trigger: signOutConfirmed)
        }
        .environment(submissionService)
    }
}

// MARK: - DashboardContent

private struct DashboardContent: View {
    @Bindable var viewModel: DashboardViewModel
    @Binding var path: NavigationPath

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                StatsRowView(
                    balance: viewModel.profile.map { Double($0.creditsBalanceCents) / 100 },
                    activeCount: viewModel.activeCount,
                    pendingCount: viewModel.pendingCount
                )

                DashboardCardView(
                    title: "Current Gigs",
                    subtitle: viewModel.activeCount == 0
                        ? "No active gigs yet"
                        : "\(viewModel.activeCount) active gig\(viewModel.activeCount == 1 ? "" : "s")",
                    icon: "checkmark.circle.fill"
                ) {
                    path.append(AppDestination.currentGigs)
                }

                DashboardCardView(
                    title: "Browse Gigs",
                    subtitle: "Find new data collection opportunities",
                    icon: "briefcase.fill"
                ) {
                    path.append(AppDestination.gigList)
                }

                DashboardCardView(
                    title: "My Applications",
                    subtitle: "\(viewModel.activeCount) active · \(viewModel.pendingCount) pending",
                    icon: "doc.text.fill"
                ) {
                    path.append(AppDestination.applicationsList)
                }
            }
            .padding()
        }
    }
}

// MARK: - StatsRowView

private struct StatsRowView: View {
    let balance: Double?
    let activeCount: Int
    let pendingCount: Int

    var body: some View {
        HStack(spacing: 12) {
            StatCellView(
                label: "Earnings",
                value: (balance ?? 0).formatted(.currency(code: "USD"))
            )
            StatCellView(
                label: "Active",
                value: activeCount.formatted()
            )
            StatCellView(
                label: "Pending",
                value: pendingCount.formatted()
            )
        }
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
    }
}

// MARK: - StatCellView

private struct StatCellView: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .bold()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - DashboardCardView

private struct DashboardCardView: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .frame(width: 44, height: 44)
                    .background(.tint.opacity(0.12), in: .rect(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding()
            .background(.regularMaterial, in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DashboardView()
        .environment(AuthRouter())
}
