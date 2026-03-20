//
//  GigListViewModel.swift
//  datagigios
//

import Foundation

@Observable
@MainActor
final class GigListViewModel {
    var gigs: [Gig] = []
    var isLoading = false
    var error: String?

    func loadGigs() async {
        isLoading = true
        error = nil
        do {
            let fetched: [Gig] = try await APIClient.shared.request(
                "/gigs",
                method: "GET",
                body: nil as String?,
                auth: nil
            )
            gigs = fetched
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
