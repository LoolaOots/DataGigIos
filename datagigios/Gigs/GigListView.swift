//
//  GigListView.swift
//  datagigios
//

import SwiftUI

struct GigListView: View {
    @State private var viewModel = GigListViewModel()

    var body: some View {
        List {
            if viewModel.isLoading && viewModel.gigs.isEmpty {
                ForEach(0..<6, id: \.self) { _ in
                    GigRowSkeletonView()
                        .listRowSeparator(.hidden)
                }
            } else {
                ForEach(viewModel.gigs) { gig in
                    NavigationLink(value: NavDestination.gigDetail(gig.id)) {
                        GigRowView(gig: gig)
                    }
                    .accessibilityLabel("View \(gig.title) by \(gig.companyName), \(payoutRange(for: gig))")
                    .accessibilityHint("Opens gig details")
                }
            }
        }
        .listStyle(.insetGrouped)
        .allowsHitTesting(!(viewModel.isLoading && viewModel.gigs.isEmpty))
        .overlay {
            if viewModel.error != nil, viewModel.gigs.isEmpty {
                ContentUnavailableView {
                    Label("Unable to Load Gigs", systemImage: "exclamationmark.triangle.fill")
                } description: {
                    Text("Please try again later.")
                } actions: {
                    Button("Retry") {
                        Task { await viewModel.loadGigs() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("Gigs")
        .refreshable {
            await viewModel.loadGigs()
        }
        .task {
            await viewModel.loadGigs()
        }
    }
}

private func payoutRange(for gig: Gig) -> String {
    let min = (Double(gig.minRateCents) / 100).formatted(.currency(code: "USD"))
    let max = (Double(gig.maxRateCents) / 100).formatted(.currency(code: "USD"))
    return "\(min)–\(max)"
}

// MARK: - GigRowView

private struct GigRowView: View {
    let gig: Gig

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(gig.title)
                .font(.headline)
                .lineLimit(2)

            Text(gig.companyName)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Text("Activity: \(gig.activityType.replacing("_", with: " ").capitalized)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(payoutRange)
                    .font(.caption)
                    .bold()
                    .foregroundStyle(.green)
            }

            if !gig.deviceTypes.isEmpty {
                DeviceTypePills(deviceTypes: gig.deviceTypes)
            }
        }
        .padding(.vertical, 4)
    }

    private var payoutRange: String {
        let min = (Double(gig.minRateCents) / 100).formatted(.currency(code: "USD"))
        let max = (Double(gig.maxRateCents) / 100).formatted(.currency(code: "USD"))
        return "\(min)–\(max)"
    }
}

// MARK: - DeviceTypePills

private struct DeviceTypePills: View {
    let deviceTypes: [String]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(deviceTypes, id: \.self) { deviceType in
                Label(deviceTypeLabel(deviceType), systemImage: deviceTypeIcon(deviceType))
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.tint.opacity(0.12), in: .capsule)
                    .foregroundStyle(.tint)
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

// MARK: - GigRowSkeletonView

private struct GigRowSkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 4)
                .fill(.quaternary)
                .frame(height: 18)
                .frame(maxWidth: .infinity)

            RoundedRectangle(cornerRadius: 4)
                .fill(.quaternary)
                .frame(width: 140, height: 14)

            RoundedRectangle(cornerRadius: 4)
                .fill(.quaternary)
                .frame(width: 100, height: 12)
        }
        .padding(.vertical, 4)
        .opacity(isAnimating ? 0.4 : 1.0)
        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear { isAnimating = true }
    }
}

#Preview {
    NavigationStack {
        GigListView()
    }
}
