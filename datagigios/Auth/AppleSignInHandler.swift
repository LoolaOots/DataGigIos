//
//  AppleSignInHandler.swift
//  datagigios
//

import AuthenticationServices
import Foundation

// MARK: - Apple auth response

private struct AppleAuthResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let userId: String
}

// MARK: - AppleSignInHandler

@MainActor
final class AppleSignInHandler {

    func handleCompletion(_ result: Result<ASAuthorization, Error>) async throws -> Session {
        let authorization = try result.get()
        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = credential.identityToken,
            let identityToken = String(data: tokenData, encoding: .utf8)
        else {
            throw NetworkError.serverError(0)
        }
        let response: AppleAuthResponse = try await APIClient.shared.request(
            "/auth/apple",
            method: "POST",
            body: ["identity_token": identityToken],
            auth: nil
        )
        return Session(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            userId: response.userId
        )
    }
}
