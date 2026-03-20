//
//  AuthRouter.swift
//  datagigios
//

import Foundation

// MARK: - Refresh response shape

private struct RefreshResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}

// MARK: - AuthRouter

@Observable
@MainActor
final class AuthRouter {
    var session: Session?

    private let keychain = KeychainService()

    // MARK: - Launch

    func loadSession() async {
        guard
            let accessToken  = keychain.load(key: KeychainService.Key.accessToken),
            let refreshToken = keychain.load(key: KeychainService.Key.refreshToken),
            let userId       = keychain.load(key: KeychainService.Key.userId)
        else {
            session = nil
            return
        }

        // Attempt token refresh on launch to ensure freshness
        do {
            let refreshed: RefreshResponse = try await APIClient.shared.request(
                "/auth/refresh",
                method: "POST",
                body: ["refresh_token": refreshToken],
                auth: nil
            )
            let newSession = Session(
                accessToken:  refreshed.accessToken,
                refreshToken: refreshed.refreshToken,
                userId:       userId
            )
            saveSession(newSession)
        } catch NetworkError.unauthorized {
            // Refresh token is invalid — clear and show landing
            clearSession()
        } catch {
            // Network unavailable — use cached tokens optimistically
            session = Session(
                accessToken:  accessToken,
                refreshToken: refreshToken,
                userId:       userId
            )
        }
    }

    // MARK: - Save

    func saveSession(_ newSession: Session) {
        do {
            try keychain.save(key: KeychainService.Key.accessToken,  value: newSession.accessToken)
            try keychain.save(key: KeychainService.Key.refreshToken, value: newSession.refreshToken)
            try keychain.save(key: KeychainService.Key.userId,       value: newSession.userId)
            session = newSession
        } catch {
            // If Keychain write fails we still set in-memory session;
            // next launch will need to re-authenticate.
            session = newSession
        }
    }

    // MARK: - Clear

    func clearSession() {
        keychain.delete(key: KeychainService.Key.accessToken)
        keychain.delete(key: KeychainService.Key.refreshToken)
        keychain.delete(key: KeychainService.Key.userId)
        session = nil
    }
}
