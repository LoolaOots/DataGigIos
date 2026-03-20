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
                    appleButton
                    emailButton
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

    // MARK: - Apple button

    private var appleButton: some View {
        Button(action: handleAppleSignIn) {
            HStack {
                if isAppleLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "applelogo")
                }
                Text("Continue with Apple")
                    .bold()
            }
            .frame(maxWidth: .infinity, minHeight: 50)
        }
        .buttonStyle(.borderedProminent)
        .tint(.black)
        .disabled(isAppleLoading)
    }

    // MARK: - Email button

    private var emailButton: some View {
        Button(action: { showEmailEntry = true }) {
            HStack {
                Image(systemName: "envelope")
                Text("Continue with Email")
                    .bold()
            }
            .frame(maxWidth: .infinity, minHeight: 50)
        }
        .buttonStyle(.bordered)
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

#Preview {
    AuthView()
        .environment(AuthRouter())
}
