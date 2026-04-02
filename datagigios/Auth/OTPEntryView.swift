//
//  OTPEntryView.swift
//  datagigios
//

import SwiftUI

// MARK: - OTP verify response

private struct OTPVerifyResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let userId: String
}

// MARK: - OTP send response (reused for resend)

private struct OTPSendResponse: Decodable {
    let message: String
}

// MARK: - OTPEntryView

struct OTPEntryView: View {
    let email: String

    @Environment(AuthRouter.self) private var authRouter
    @Environment(\.dismiss) private var dismiss

    @State private var digits: [String] = Array(repeating: "", count: 6)
    @State private var isVerifying = false
    @State private var isResending = false
    @State private var errorMessage: String?
    @State private var resendMessage: String?
    @State private var verifySucceeded = false
    @State private var verifyFailed = false

    @FocusState private var focusedField: Int?

    private var otpToken: String {
        digits.joined()
    }

    private var isComplete: Bool {
        digits.allSatisfy { $0.count == 1 }
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Header
            VStack(spacing: 8) {
                Image(systemName: "lock.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)

                Text("Check your email")
                    .font(.title2)
                    .bold()

                Text("Enter the 6-digit code sent to\n**\(email)**")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Digit input row
            DigitRow(digits: $digits, focusedField: $focusedField, advance: advance)

            // Error / resend messages
            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if let resendMessage {
                Text(resendMessage)
                    .foregroundStyle(.green)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Verify button
            Button(action: verify) {
                Group {
                    if isVerifying {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Verify")
                            .bold()
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isComplete || isVerifying)
            .padding(.horizontal)

            // Resend
            Button(action: resendCode) {
                if isResending {
                    ProgressView()
                } else {
                    Text("Resend code")
                        .font(.footnote)
                }
            }
            .foregroundStyle(.secondary)
            .disabled(isResending)

            Spacer()
        }
        .navigationTitle("Enter Code")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            focusedField = 0
        }
        .sensoryFeedback(.success, trigger: verifySucceeded)
        .sensoryFeedback(.error, trigger: verifyFailed)
    }

    private func advance(from index: Int) {
        let next = index + 1
        if next < 6 {
            focusedField = next
        } else {
            focusedField = nil
        }
    }

    // MARK: - Verify

    private func verify() {
        guard isComplete else { return }
        isVerifying = true
        errorMessage = nil
        Task {
            do {
                let response: OTPVerifyResponse = try await APIClient.shared.request(
                    "/auth/otp/verify",
                    method: "POST",
                    body: ["email": email, "token": otpToken],
                    auth: nil
                )
                let session = Session(
                    accessToken:  response.accessToken,
                    refreshToken: response.refreshToken,
                    userId:       response.userId
                )
                authRouter.saveSession(session)
                verifySucceeded = true
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                verifyFailed.toggle()
            }
            isVerifying = false
        }
    }

    // MARK: - Resend

    private func resendCode() {
        isResending = true
        resendMessage = nil
        errorMessage = nil
        Task {
            do {
                let _: OTPSendResponse = try await APIClient.shared.request(
                    "/auth/otp/send",
                    method: "POST",
                    body: ["email": email],
                    auth: nil
                )
                resendMessage = "Code resent!"
                // Clear the digit fields for fresh entry
                digits = Array(repeating: "", count: 6)
                focusedField = 0
            } catch {
                errorMessage = error.localizedDescription
            }
            isResending = false
        }
    }
}

// MARK: - DigitRow

private struct DigitRow: View {
    @Binding var digits: [String]
    @FocusState.Binding var focusedField: Int?
    let advance: (Int) -> Void

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<6, id: \.self) { index in
                DigitCell(
                    digit: $digits[index],
                    isFocused: focusedField == index,
                    onCommit: {
                        advance(index)
                    }
                )
                .focused($focusedField, equals: index)
                .onChange(of: digits[index]) { _, newValue in
                    // Keep only last character entered
                    if newValue.count > 1 {
                        digits[index] = String(newValue.suffix(1))
                    }
                    // Filter to digits only
                    digits[index] = digits[index].filter(\.isNumber)
                    if !digits[index].isEmpty {
                        advance(index)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - DigitCell

private struct DigitCell: View {
    @Binding var digit: String
    let isFocused: Bool
    let onCommit: () -> Void

    var body: some View {
        TextField("", text: $digit)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.title)
            .bold()
            .frame(width: 44, height: 56)
            .background(.quaternary, in: .rect(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isFocused ? Color.accentColor : .clear, lineWidth: 2)
            )
            .submitLabel(.next)
            .onSubmit(onCommit)
    }
}

#Preview {
    NavigationStack {
        OTPEntryView(email: "test@example.com")
            .environment(AuthRouter())
    }
}
