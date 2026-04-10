//
//  AppleSignInHandler.swift
//  datagigios
//

import AuthenticationServices
import Foundation
import UIKit

// MARK: - Apple auth response

private struct AppleAuthResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let userId: String
}

// MARK: - AppleSignInHandler

@MainActor
final class AppleSignInHandler: NSObject,
                                ASAuthorizationControllerDelegate,
                                ASAuthorizationControllerPresentationContextProviding {

    // Continuation bridging the delegate callback to async/await
    private var continuation: CheckedContinuation<Session, Error>?

    // MARK: - Public entry point

    func signIn() async throws -> Session {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    // MARK: - ASAuthorizationControllerPresentationContextProviding

    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Return the key window for presentation
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        return windowScene?.windows.first(where: { $0.isKeyWindow }) ?? UIWindow()
    }

    // MARK: - ASAuthorizationControllerDelegate

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let identityToken = String(data: tokenData, encoding: .utf8)
            else {
                continuation?.resume(throwing: NetworkError.serverError(0))
                continuation = nil
                return
            }

            do {
                let response: AppleAuthResponse = try await APIClient.shared.request(
                    "/auth/apple",
                    method: "POST",
                    body: ["identity_token": identityToken],
                    auth: nil
                )
                let session = Session(
                    accessToken:  response.accessToken,
                    refreshToken: response.refreshToken,
                    userId:       response.userId
                )
                continuation?.resume(returning: session)
            } catch {
                continuation?.resume(throwing: error)
            }
            continuation = nil
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
}
