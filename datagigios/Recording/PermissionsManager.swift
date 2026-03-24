import Foundation
import CoreLocation

@Observable
@MainActor
final class PermissionsManager: NSObject {

    enum PermissionResult {
        case granted, denied
    }

    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private var onResult: ((PermissionResult) -> Void)?
    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        authorizationStatus = locationManager.authorizationStatus
    }

    /// Check current permissions. Requests if not determined. Calls `onResult` exactly once.
    func check(onResult: @escaping (PermissionResult) -> Void) {
        self.onResult = onResult
        let status = locationManager.authorizationStatus
        authorizationStatus = status
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            fire(.granted)
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            // Result arrives via locationManagerDidChangeAuthorization delegate callback below
        default:
            fire(.denied)
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
                self.fire(.granted)
            case .denied, .restricted:
                self.fire(.denied)
            default:
                break   // .notDetermined — waiting for user response
            }
        }
    }
}
