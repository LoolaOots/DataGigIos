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

    func load(accessToken: String, authRouter: AuthRouter? = nil) async {
        isLoading = true
        error = nil
        do {
            try await fetchAll(accessToken: accessToken)
        } catch NetworkError.unauthorized where authRouter != nil {
            // Token was stale — refresh and retry once
            await authRouter!.loadSession()
            guard let freshToken = authRouter!.session?.accessToken else {
                // Refresh failed; AuthRouter cleared the session, view will pop to landing
                isLoading = false
                return
            }
            do {
                try await fetchAll(accessToken: freshToken)
            } catch {
                self.error = error.localizedDescription
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func fetchAll(accessToken: String) async throws {
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
    }
}
