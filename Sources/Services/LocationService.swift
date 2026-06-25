import CoreLocation

/// One-shot, When-In-Use location fix. Fully optional: if permission is denied
/// or the fix times out, we simply return nil and never block signing.
final class LocationService: NSObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()
    private var completion: ((CLLocationCoordinate2D?) -> Void)?
    private var didFinish = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// Requests a single coordinate. Calls back with nil if unavailable.
    func requestOneShot(completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        self.completion = completion
        self.didFinish = false

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            // The delegate callback will trigger the request once authorized.
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            finish(with: nil)
        }

        // Safety timeout so we never hang the signing flow.
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [weak self] in
            self?.finish(with: nil)
        }
    }

    private func finish(with coord: CLLocationCoordinate2D?) {
        guard !didFinish else { return }
        didFinish = true
        let cb = completion
        completion = nil
        cb?(coord)
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if completion != nil && !didFinish { manager.requestLocation() }
        case .denied, .restricted:
            finish(with: nil)
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        finish(with: locations.last?.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(with: nil)
    }
}
