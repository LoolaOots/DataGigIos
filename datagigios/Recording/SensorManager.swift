import Foundation
import CoreMotion
import CoreLocation

@Observable
@MainActor
final class SensorManager: NSObject {

    // MARK: - State (observable)
    private(set) var isRecording = false

    // MARK: - Private
    private let motionManager = CMMotionManager()
    private let altimeter = CMAltimeter()
    private let pedometer = CMPedometer()
    private let locationManager = CLLocationManager()

    private var frames: [SensorFrame] = []
    private var label: ApplicationLabel?
    private var gigSession: (gigId: String, gigTitle: String, companyName: String, assignmentCode: String)?
    private var recordingTimer: Timer?
    private var recordingStartTime = Date()

    // Live location/altitude state (updated by delegates)
    private var lastLocation: CLLocation?
    private var lastRelativeAltitude: Double?
    private var lastPressure: Double?
    private var lastCadence: Double?
    private var lastMagX: Double?
    private var lastMagY: Double?
    private var lastMagZ: Double?

    // MARK: - Init
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.headingFilter = kCLHeadingFilterNone
    }

    // MARK: - Public API

    /// Starts all sensors and begins collecting frames at the given sample rate.
    func startRecording(
        label: ApplicationLabel,
        gigId: String,
        gigTitle: String,
        companyName: String,
        assignmentCode: String,
        sampleRate: SampleRate = .standard
    ) {
        guard !isRecording else { return }
        self.label = label
        self.gigSession = (gigId, gigTitle, companyName, assignmentCode)
        frames = []
        recordingStartTime = Date()
        isRecording = true

        // Location
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()

        // Device motion
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = sampleRate.interval
            motionManager.startDeviceMotionUpdates()
        }

        // Magnetometer (separate API — CMDeviceMotion.magneticField is always 0)
        if motionManager.isMagnetometerAvailable {
            motionManager.magnetometerUpdateInterval = sampleRate.interval
            motionManager.startMagnetometerUpdates(to: .main) { [weak self] data, _ in
                guard let self, let data else { return }
                self.lastMagX = data.magneticField.x
                self.lastMagY = data.magneticField.y
                self.lastMagZ = data.magneticField.z
            }
        }

        // Altimeter
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, _ in
                guard let self, let data else { return }
                self.lastRelativeAltitude = data.relativeAltitude.doubleValue
                self.lastPressure = data.pressure.doubleValue
            }
        }

        // Pedometer cadence
        if CMPedometer.isCadenceAvailable() {
            let authStatus = CMPedometer.authorizationStatus()
            if authStatus != .authorized {
                print("[SensorManager] CMPedometer auth denied/restricted: \(authStatus.rawValue)")
            } else {
                pedometer.startUpdates(from: Date()) { [weak self] data, error in
                    if let error {
                        print("[SensorManager] CMPedometer error: \(error)")
                        return
                    }
                    guard let self, let data else { return }
                    print("[SensorManager] CMPedometer update — currentCadence: \(String(describing: data.currentCadence)), currentPace: \(String(describing: data.currentPace)), numberOfSteps: \(data.numberOfSteps)")
                    guard let cadence = data.currentCadence else { return }
                    Task { @MainActor in
                        self.lastCadence = cadence.doubleValue
                    }
                }
            }
        }

        let interval = sampleRate.interval
        Task {
            // Wait for CMAltimeter's first reading (max 1.5 s) so pressure is
            // populated from frame 1.  This is much shorter than the original
            // 1-second hard delay and aborts early as soon as data arrives.
            let deadline = Date.now.addingTimeInterval(1.5)
            while self.lastPressure == nil, Date.now < deadline {
                try? await Task.sleep(for: .milliseconds(50))
            }
            self.recordingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.captureFrame() }
            }
        }
    }

    /// Stops all sensors and returns the completed session.
    @discardableResult
    func stopRecording() -> GigRecordingSession? {
        guard isRecording, let label, let gig = gigSession else { return nil }
        let endTime = Date()
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil

        motionManager.stopDeviceMotionUpdates()
        motionManager.stopMagnetometerUpdates()
        altimeter.stopRelativeAltitudeUpdates()
        pedometer.stopUpdates()
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        lastMagX = nil
        lastMagY = nil
        lastMagZ = nil

        let session = GigRecordingSession(
            id: UUID(),
            gigId: gig.gigId,
            gigTitle: gig.gigTitle,
            companyName: gig.companyName,
            labelId: label.id,
            labelName: label.labelName,
            assignmentCode: gig.assignmentCode,
            startTime: recordingStartTime,
            endTime: endTime,
            intendedDurationSeconds: label.durationSeconds,
            frames: frames
        )
        frames = []
        self.label = nil
        self.gigSession = nil
        return session
    }

    // MARK: - Private

    private func captureFrame() {
        guard isRecording, let labelName = label?.labelName else { return }
        let motion = motionManager.deviceMotion
        let location = lastLocation
        let toDegrees = 180.0 / Double.pi

        // Convert boot-relative motion timestamp to wall clock
        let timestamp: Date
        if let motion {
            timestamp = Date(timeIntervalSinceNow: motion.timestamp - ProcessInfo.processInfo.systemUptime)
        } else {
            timestamp = Date()
        }

        let trueHeading: Double? = {
            guard let h = locationManager.heading?.trueHeading, h >= 0 else { return nil }
            return h
        }()
        let speed: Double? = {
            guard let s = location?.speed, s >= 0 else { return nil }
            return s
        }()

        let frame = SensorFrame(
            timestamp: timestamp,
            labelName: labelName,
            pitch: motion.map { $0.attitude.pitch },
            roll: motion.map { $0.attitude.roll },
            yaw: motion.map { $0.attitude.yaw },
            latitude: location?.coordinate.latitude,
            longitude: location?.coordinate.longitude,
            relativeAltitude: lastRelativeAltitude,
            absoluteAltitude: location?.altitude,
            pressure: lastPressure,
            trueHeading: trueHeading,
            speed: speed,
            accelX: motion.map { $0.userAcceleration.x },
            accelY: motion.map { $0.userAcceleration.y },
            accelZ: motion.map { $0.userAcceleration.z },
            gForceX: motion.map { $0.userAcceleration.x + $0.gravity.x },
            gForceY: motion.map { $0.userAcceleration.y + $0.gravity.y },
            gForceZ: motion.map { $0.userAcceleration.z + $0.gravity.z },
            gravityX: motion.map { $0.gravity.x },
            gravityY: motion.map { $0.gravity.y },
            gravityZ: motion.map { $0.gravity.z },
            gyroX: motion.map { $0.rotationRate.x * toDegrees },
            gyroY: motion.map { $0.rotationRate.y * toDegrees },
            gyroZ: motion.map { $0.rotationRate.z * toDegrees },
            magX: lastMagX,
            magY: lastMagY,
            magZ: lastMagZ,
            cadence: lastCadence
        )
        frames.append(frame)
    }
}

// MARK: - CLLocationManagerDelegate
extension SensorManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in self.lastLocation = loc }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Auth changes handled by PermissionsManager; no action needed here
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Sensor unavailability is handled by nil fields; no crash
    }
}
