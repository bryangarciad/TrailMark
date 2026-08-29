import Foundation
import CoreMotion
import Observation

@MainActor
@Observable
public final class MotionManager {
    public enum Activity: String, Sendable {
        case stationary, walking, running, cycling, automotive, unknown
        
        public var label: String { rawValue.capitalized } // Running, Walking

        public var symbolName: String {
            switch self {
            case .stationary: "figure.stand"
            case .walking: "figure.walk"
            case .running: "figure.run"
            case .cycling: "bicycle"
            case .automotive: "car.fill"
            case .unknown: "questionmark"
            }
        }
    }
    
    // Pedometer Activity Manager Data
    public private(set) var stepsToday: Int = 0
    public private(set) var cadence: Double = 0
    public private(set) var activity: Activity = .unknown
    // Raw Acc Data
    public private(set) var acceleration: (Double, Double, Double) = (0, 0, 0)
    // Raw Giro Data
    public private(set) var giroscope: (Double, Double, Double) = (0, 0, 0)

    /// Magnitude of user acceleration in g — the raw XYZ boiled down to one number
    /// a view can actually show.
    public var accelerationMagnitude: Double {
        let (x, y, z) = acceleration
        return (x * x + y * y + z * z).squareRoot()
    }

    public init() {}
    
    public static var isPedometerAvailable: Bool { CMPedometer.isStepCountingAvailable() }
    public static var isActivityAvailable: Bool { CMMotionActivityManager.isActivityAvailable() }
    
    private let pedometer = CMPedometer()
    private let activityManager = CMMotionActivityManager()
    private let motionManager = CMMotionManager()

    // MARK: - Start / Stop

    public func start() {
        startPedometer()
        startActivityUpdates()
        startAccelerometer()
    }

    public func stop() {
        pedometer.stopUpdates()
        activityManager.stopActivityUpdates()
        motionManager.stopDeviceMotionUpdates()
    }

    private func startPedometer() {
        guard MotionManager.isPedometerAvailable else { return }
        let startOfDayToday = Calendar.current.startOfDay(for: Date()) // 2026-08-10T00:00:00.000-06:00
        
        pedometer.startUpdates(from: startOfDayToday) { [weak self] data, error  in
            guard let data else { return }
            let steps = data.numberOfSteps.intValue
            // Cadance/Pace is given always in steps/second -> steps/minute
            let cadence = (data.currentCadence?.doubleValue ?? 0) * 60
            
            Task { @MainActor in
                self?.stepsToday = steps
                self?.cadence = cadence
            }
        }
    }
    
    private func startAccelerometer() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 0.1 // 1/10 = 10hz, 1/5 = 5hz, 1/2 = 2hz
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            self?.acceleration = (motion?.userAcceleration.x ?? 0, motion?.userAcceleration.y ?? 0, motion?.userAcceleration.z ?? 0)
            self?.giroscope = (motion?.rotationRate.x ?? 0, motion?.rotationRate.y ?? 0, motion?.rotationRate.z ?? 0)
        }
    }
    
    private func startActivityUpdates() {
        guard Self.isActivityAvailable else { return }
        
        activityManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let activity else { return }
            let resolvedActivity: Activity
            
            if activity.confidence == CMMotionActivityConfidence.low {
                return
            }
            
            if activity.walking { resolvedActivity = .walking }
            else if activity.stationary { resolvedActivity = .stationary }
            else if activity.running { resolvedActivity = .running }
            else if activity.automotive { resolvedActivity = .automotive }
            else if activity.cycling { resolvedActivity = .cycling }
            else if activity.unknown { resolvedActivity = .unknown }
            else { resolvedActivity = .unknown }
            
            self?.activity = resolvedActivity
        }
    }
}
