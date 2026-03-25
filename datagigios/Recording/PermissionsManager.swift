import Foundation
import CoreLocation
import CoreMotion

@Observable
@MainActor
final class PermissionsManager: NSObject {

    enum PermissionResult {
        case granted, denied
    }

    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private var onResult: ((PermissionResult) -> Void)?
    private let locationManager = CLLocationManager()
    private var motionActivityManager: CMMotionActivityManager?

    override init() {
        super.init()
        locationManager.delegate = self
        authorizationStatus = locationManager.authorizationStatus
    }

    /// Check location + motion permissions. Requests if not determined. Calls `onResult` exactly once.
    func check(onResult: @escaping (PermissionResult) -> Void) {
        self.onResult = onResult
        let status = locationManager.authorizationStatus
        authorizationStatus = status
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            checkMotion()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            // Continues in locationManagerDidChangeAuthorization
        default:
            fire(.denied)
        }
    }

    private func checkMotion() {
        guard CMMotionActivityManager.isActivityAvailable() else {
            fire(.granted)
            return
        }
        let manager = CMMotionActivityManager()
        motionActivityManager = manager
        // Querying triggers the Motion & Fitness permission dialog if not yet determined
        manager.queryActivityStarting(from: Date(), to: Date(), to: .main) { [weak self] _, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.motionActivityManager = nil
                if error == nil {
                    self.fire(.granted)
                } else {
                    let motionStatus = CMMotionActivityManager.authorizationStatus()
                    self.fire(motionStatus == .authorized ? .granted : .denied)
                }
            }
        }
    }

    private func fire(_ result: PermissionResult) {
        let cb = onResult
        onResult = nil
        cb?(result)
    }
}

extension PermissionsManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.authorizationStatus = manager.authorizationStatus
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.checkMotion()
            case .denied, .restricted:
                self.fire(.denied)
            default:
                break
            }
        }
    }
}
