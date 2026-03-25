//
//  DataUnavailableView.swift
//  datagigios
//

import SwiftUI

struct DataUnavailableView: View {
    let retryAction: (() -> Void)?

    init(retryAction: (() -> Void)? = nil) {
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Unable to retrieve this data.")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("Please try again later.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let retryAction {
                Button("Retry", action: retryAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
