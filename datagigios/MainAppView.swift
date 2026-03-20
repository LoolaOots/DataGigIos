//
//  MainAppView.swift
//  datagigios
//
//  Placeholder for the authenticated app experience.
//  Will be replaced once the post-auth flows (recording, submissions) are built.
//

import SwiftUI

struct MainAppView: View {
    @Environment(AuthRouter.self) private var authRouter

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)

                Text("You're signed in!")
                    .font(.title2)
                    .bold()

                Text("More features coming soon.")
                    .foregroundStyle(.secondary)

                Button("Sign Out") {
                    authRouter.clearSession()
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.red)
            }
            .navigationTitle("DataGigs")
        }
    }
}

#Preview {
    MainAppView()
        .environment(AuthRouter())
}
