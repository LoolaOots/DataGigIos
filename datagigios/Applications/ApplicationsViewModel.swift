//
//  ApplicationsViewModel.swift
//  datagigios
//

import Foundation

// MARK: - ApplicationFilter

enum ApplicationFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case active = "Active"
    case pending = "Pending"
    case denied = "Denied"

    var id: String { rawValue }
}

// MARK: - ApplicationsViewModel

@Observable
@MainActor
final class ApplicationsViewModel {
    var applications: [Application] = []
    var selectedDetail: ApplicationDetail?
    var filter: ApplicationFilter = .all
    var isLoading = false
    var isLoadingDetail = false
    var error: String?

    var filteredApplications: [Application] {
        switch filter {
        case .all:
            return applications
        case .active:
            return applications.filter { $0.status == "accepted" }
        case .pending:
            return applications.filter { $0.status == "pending" }
        case .denied:
            return applications.filter { $0.status == "denied" }
        }
    }

    func load(accessToken: String) async {
        isLoading = true
        error = nil
        do {
            let fetched: [Application] = try await APIClient.shared.request(
                "/applications",
                method: "GET",
                body: nil as String?,
                auth: accessToken
            )
            applications = fetched
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func loadDetail(applicationId: String, accessToken: String) async {
        isLoadingDetail = true
        do {
            let detail: ApplicationDetail = try await APIClient.shared.request(
                "/applications/\(applicationId)",
                method: "GET",
                body: nil as String?,
                auth: accessToken
            )
            selectedDetail = detail
        } catch {
            self.error = error.localizedDescription
        }
        isLoadingDetail = false
    }
}
