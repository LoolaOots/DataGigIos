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
}

// MARK: - DashboardView

struct DashboardView: View {
    @Environment(AuthRouter.self) private var authRouter
    @State private var viewModel = DashboardViewModel()
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if viewModel.isLoading && viewModel.profile == nil {
                    ProgressView("Loading…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    dashboardContent
                }
            }
            .navigationTitle("DataGigs")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sign Out") {
                        authRouter.clearSession()
                    }
                    .foregroundStyle(.red)
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
        }
    }

    // MARK: - Dashboard content

    private var dashboardContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let errorMessage = viewModel.error {
                    ErrorBannerView(message: errorMessage)
                }

                StatsRowView(
                    balance: viewModel.profile.map { Double($0.creditsBalanceCents) / 100 },
                    activeCount: viewModel.activeCount,
                    pendingCount: viewModel.pendingCount
                )

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
            }
            .padding()
            .background(.regularMaterial, in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ErrorBannerView

private struct ErrorBannerView: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.1), in: .rect(cornerRadius: 12))
    }
}

#Preview {
    DashboardView()
        .environment(AuthRouter())
}
