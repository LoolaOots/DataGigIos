//
//  LandingView.swift
//  datagigios
//

import SwiftUI

struct LandingView: View {
    @State private var showAuth = false
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                Spacer()

                // MARK: Brand
                VStack(spacing: 16) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.tint)

                    Text("DataGigs")
                        .font(.largeTitle)
                        .bold()

                    Text("Earn money doing the things you love")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                // MARK: Actions
                VStack(spacing: 12) {
                    Button("Browse Gigs", systemImage: "briefcase") {
                        path.append(NavDestination.gigList)
                    }
                    .buttonStyle(.primary)

                    Button("Sign Up / Sign In", systemImage: "person.crop.circle") {
                        showAuth = true
                    }
                    .buttonStyle(.primary)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .navigationDestination(for: NavDestination.self) { destination in
                switch destination {
                case .gigList:
                    GigListView()
                case .gigDetail(let id):
                    GigDetailView(gigId: id)
                }
            }
            .sheet(isPresented: $showAuth) {
                AuthView()
            }
        }
    }
}

// MARK: - NavDestination

enum NavDestination: Hashable {
    case gigList
    case gigDetail(String)
}

#Preview {
    LandingView()
        .environment(AuthRouter())
}
