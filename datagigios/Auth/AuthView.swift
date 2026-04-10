//
//  AuthView.swift
//  datagigios
//

import SwiftUI

struct AuthView: View {
    @Environment(AuthRouter.self) private var authRouter
    @Environment(\.dismiss) private var dismiss

    @State private var showEmailEntry = false
    @State private var isAppleLoading = false
    @State private var appleError: String?
    @State private var appleSignInHandler = AppleSignInHandler()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                // MARK: Header
                VStack(spacing: 8) {
                    Text("Welcome to DataGigs")
                        .font(.title)
                        .bold()
                        .multilineTextAlignment(.center)

                    Text("Sign in or create an account to get started")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                Spacer()

                // MARK: Buttons
                VStack(spacing: 12) {
                    AppleSignInButton(isLoading: isAppleLoading, onTap: handleAppleSignIn)
                    EmailSignInButton(onTap: { showEmailEntry = true })
                }
                .padding(.horizontal)

                // MARK: Footer note
                Text("New here? An account will be created automatically.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 16)

                Spacer()

                // MARK: Error
                if let appleError {
                    Text(appleError)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close", systemImage: "xmark") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .navigationDestination(isPresented: $showEmailEntry) {
                EmailEntryView()
            }
        }
    }

    // MARK: - Apple sign-in action

    private func handleAppleSignIn() {
        isAppleLoading = true
        appleError = nil
        Task {
            do {
                let session = try await appleSignInHandler.signIn()
                authRouter.saveSession(session)
            } catch {
                appleError = error.localizedDescription
            }
            isAppleLoading = false
        }
    }
}

// MARK: - Apple Sign In Button

private struct AppleSignInButton: View {
    let isLoading: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Label("Continue with Apple", systemImage: "applelogo")
            }
        }
        .buttonStyle(.primary)
        .tint(.black)
        .disabled(isLoading)
    }
}

// MARK: - Email Sign In Button

private struct EmailSignInButton: View {
    let onTap: () -> Void

    var body: some View {
        Button("Continue with Email", systemImage: "envelope", action: onTap)
            .buttonStyle(.primary)
    }
}

#Preview {
    AuthView()
        .environment(AuthRouter())
}
