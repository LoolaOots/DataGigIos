//
//  GigDetailViewModel.swift
//  datagigios
//

import Foundation

// MARK: - ApplyState

enum ApplyState {
    case signInRequired
    case canApply
    case applied
}

// MARK: - GigDetailViewModel

@Observable
@MainActor
final class GigDetailViewModel {
    var gig: GigDetail?
    var isLoading = true
    var error: String?

    private let gigId: String
    private let session: Session?
    private let existingApplications: [Application]

    init(gigId: String, session: Session?, existingApplications: [Application]) {
        self.gigId = gigId
        self.session = session
        self.existingApplications = existingApplications
    }

    var applyState: ApplyState {
        guard session != nil else { return .signInRequired }
        // Gig not yet loaded — fall back to signInRequired (safe: opens auth sheet,
        // which is a no-op for a signed-in user, and cannot trigger navigation to ApplyView)
        guard let gig else { return .signInRequired }
        let alreadyApplied = existingApplications.contains { $0.gigId == gig.id }
        return alreadyApplied ? .applied : .canApply
    }

    func loadGig() async {
        isLoading = true
        error = nil
        do {
            let fetched: GigDetail = try await APIClient.shared.request(
                "/gigs/\(gigId)",
                method: "GET",
                body: nil as String?,
                auth: nil
            )
            gig = fetched
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
