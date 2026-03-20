//
//  EmailEntryView.swift
//  datagigios
//

import SwiftUI

// MARK: - OTP send response

private struct OTPSendResponse: Decodable {
    let message: String
}

// MARK: - EmailEntryView

struct EmailEntryView: View {
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var navigateToOTP = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Header
            VStack(spacing: 8) {
                Image(systemName: "envelope.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)

                Text("Enter your email")
                    .font(.title2)
                    .bold()

                Text("We'll send you a 6-digit code to sign in.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Email field
            TextField("you@example.com", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding()
                .background(.quaternary, in: .rect(cornerRadius: 12))
                .padding(.horizontal)

            // Error
            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Send code button
            Button(action: sendCode) {
                Group {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Send Code")
                            .bold()
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .disabled(email.isEmpty || isLoading)
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("Sign In with Email")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToOTP) {
            OTPEntryView(email: email)
        }
    }

    // MARK: - Send OTP

    private func sendCode() {
        guard !email.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let _: OTPSendResponse = try await APIClient.shared.request(
                    "/auth/otp/send",
                    method: "POST",
                    body: ["email": email],
                    auth: nil
                )
                navigateToOTP = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        EmailEntryView()
    }
}
