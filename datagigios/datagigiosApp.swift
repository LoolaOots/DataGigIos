//
//  datagigiosApp.swift
//  datagigios
//
//  Created by Nat on 3/17/26.
//

import SwiftUI

@main
struct datagigiosApp: App {
    @State private var authRouter = AuthRouter()

    var body: some Scene {
        WindowGroup {
            Group {
                if authRouter.session != nil {
                    DashboardView()
                } else {
                    LandingView()
                }
            }
            .environment(authRouter)
            .task {
                await authRouter.loadSession()
            }
        }
    }
}
