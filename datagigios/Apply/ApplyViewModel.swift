//
//  ApplyViewModel.swift
//  datagigios
//

import Foundation

// MARK: - Application submit body

private struct ApplicationBody: Encodable {
    let gigId: String
    let deviceType: String
    let noteFromUser: String?
}

// MARK: - Application submit response

private struct ApplicationSubmitResponse: Decodable {
    let id: String
    let gigId: String
    let status: String
    let appliedAt: Date
}

// MARK: - ApplyViewModel

@Observable
@MainActor
final class ApplyViewModel {
    var selectedDeviceType: String
    var noteFromUser: String = ""
    var isLoading = false
    var error: String?
    var submitted = false

    private let gig: GigDetail
    private let session: Session

    var gigTitle: String { gig.title }
    var availableDeviceTypes: [String] { gig.deviceTypes }

    init(gig: GigDetail, session: Session) {
        self.gig = gig
        self.session = session
        self.selectedDeviceType = gig.deviceTypes.first ?? ""
    }

    func submit() async {
        isLoading = true
        error = nil
        do {
            let body = ApplicationBody(
                gigId: gig.id,
                deviceType: selectedDeviceType,
                noteFromUser: noteFromUser.isEmpty ? nil : noteFromUser
            )
            let _: ApplicationSubmitResponse = try await APIClient.shared.request(
                "/applications",
                method: "POST",
                body: body,
                auth: session.accessToken
            )
            submitted = true
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
