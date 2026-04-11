//
//  CurrentGigsView.swift
//  datagigios
//

import SwiftUI

struct CurrentGigsView: View {
    let applications: [Application]
    let accessToken: String

    @State private var selectedApplicationId: String?

    var body: some View {
        Group {
            if applications.isEmpty {
                ContentUnavailableView(
                    "No Active Gigs",
                    systemImage: "checkmark.circle",
                    description: Text("You don't have any accepted gigs yet. Apply to gigs and check back once accepted.")
                )
            } else {
                List(applications) { application in
                    Button {
                        selectedApplicationId = application.id
                    } label: {
                        CurrentGigRowView(application: application)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("View \(application.gigTitle)")
                    .accessibilityHint("Tap to start collecting data")
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Current Gigs")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(item: $selectedApplicationId) { id in
            ApplicationDetailView(applicationId: id, accessToken: accessToken)
        }
    }
}

// MARK: - CurrentGigRowView

private struct CurrentGigRowView: View {
    let application: Application

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
                .frame(width: 44, height: 44)
                .background(.green.opacity(0.12), in: .rect(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(application.gigTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Label(deviceTypeLabel(application.deviceType), systemImage: deviceTypeIcon(application.deviceType))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
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
