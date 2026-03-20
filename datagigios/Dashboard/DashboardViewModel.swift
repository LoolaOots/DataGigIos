//
//  DashboardViewModel.swift
//  datagigios
//

import Foundation

@Observable
@MainActor
final class DashboardViewModel {
    var profile: UserProfile?
    var applications: [Application] = []
    var isLoading = false
    var error: String?

    var activeCount: Int {
        applications.filter { $0.status == "accepted" }.count
    }

    var pendingCount: Int {
        applications.filter { $0.status == "pending" }.count
    }

    func load(accessToken: String) async {
        isLoading = true
        error = nil
        do {
            async let fetchedProfile: UserProfile = APIClient.shared.request(
                "/profile",
                method: "GET",
                body: nil as String?,
                auth: accessToken
            )
            async let fetchedApplications: [Application] = APIClient.shared.request(
                "/applications",
                method: "GET",
                body: nil as String?,
                auth: accessToken
            )
            let (resolvedProfile, resolvedApplications) = try await (fetchedProfile, fetchedApplications)
            profile = resolvedProfile
            applications = resolvedApplications
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
