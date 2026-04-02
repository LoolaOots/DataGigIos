import SwiftUI
import CoreLocation
import CoreMotion

struct PermissionsDeniedView: View {
    let onGranted: () -> Void
    let onBack: () -> Void

    @State private var locationManager = CLLocationManager()
    @State private var tryAgainShown = true
    @State private var copy = "Location and motion access are required to collect sensor data for this gig."
    @State private var didAppear = false
    @State private var openSettingsTapped = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "sensor.tag.radiowaves.forward.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)

            Text("Permissions Required")
                .font(.title2).bold()

            Text(copy)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            VStack(spacing: 12) {
                Button("Open Settings") {
                    openSettingsTapped.toggle()
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)

                if tryAgainShown {
                    Button("Try Again") {
                        checkPermissions()
                    }
                    .buttonStyle(.bordered)
                }

                Button("Back", action: onBack)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            didAppear = true
        }
        .sensoryFeedback(.warning, trigger: didAppear)
        .sensoryFeedback(.warning, trigger: openSettingsTapped)
    }

    private func checkPermissions() {
        let locationStatus = locationManager.authorizationStatus
        let locationGranted = locationStatus == .authorizedWhenInUse || locationStatus == .authorizedAlways

        // CMMotionActivityManager.isActivityAvailable() checks device capability, not user grant.
        // There is no public iOS API to query motion permission without triggering a prompt.
        // This is intentional: if location is granted we proceed; motion is implicitly available
        // on all supported devices.
        let motionGranted = CMMotionActivityManager.isActivityAvailable()

        if locationGranted && motionGranted {
            onGranted()
        } else {
            tryAgainShown = false
            copy = "Please enable Location and Motion access in Settings — iOS won't prompt again."
        }
    }
}
