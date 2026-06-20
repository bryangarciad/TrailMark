//
//  MotionManager.swift
//  TrailmarkCore
//
//  Course 2.4 — sensing motion at the source (the wrist). Wraps Core Motion's
//  pedometer (cadence), motion-activity classifier, and the accelerometer.
//

import Foundation
import CoreMotion
import Observation

@MainActor
@Observable
public final class MotionManager {

    public enum Activity: String, Sendable {
        case stationary, walking, running, cycling, automotive, unknown

        public var label: String { rawValue.capitalized }
        public var symbolName: String {
            switch self {
            case .stationary: return "figure.stand"
            case .walking: return "figure.walk"
            case .running: return "figure.run"
            case .cycling: return "bicycle"
            case .automotive: return "car.fill"
            case .unknown: return "questionmark"
            }
        }
    }

    // MARK: Published signals

    public private(set) var stepsToday: Int = 0
    /// Derived signal: current cadence in steps per minute (curriculum 2.4).
    public private(set) var cadence: Double = 0
    public private(set) var activity: Activity = .unknown
    /// Magnitude of user acceleration (g), a simple accelerometer-derived signal.
    public private(set) var accelerationMagnitude: Double = 0

    private let pedometer = CMPedometer()
    private let activityManager = CMMotionActivityManager()
    private let motionManager = CMMotionManager()

    public init() {}

    public static var isPedometerAvailable: Bool { CMPedometer.isStepCountingAvailable() }
    public static var isActivityAvailable: Bool { CMMotionActivityManager.isActivityAvailable() }

    // MARK: - Start / stop

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
        guard CMPedometer.isStepCountingAvailable() else { return }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        pedometer.startUpdates(from: startOfDay) { [weak self] data, _ in
            guard let data else { return }
            let steps = data.numberOfSteps.intValue
            // currentCadence is steps/second → convert to steps/minute.
            let cadence = (data.currentCadence?.doubleValue ?? 0) * 60
            Task { @MainActor in
                self?.stepsToday = steps
                self?.cadence = cadence
            }
        }
    }

    private func startActivityUpdates() {
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        activityManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let activity else { return }
            let resolved: Activity
            if activity.walking { resolved = .walking }
            else if activity.running { resolved = .running }
            else if activity.cycling { resolved = .cycling }
            else if activity.automotive { resolved = .automotive }
            else if activity.stationary { resolved = .stationary }
            else { resolved = .unknown }
            self?.activity = resolved
        }
    }

    private func startAccelerometer() {
        guard motionManager.isDeviceMotionAvailable else { return }
        // 10 Hz is plenty for a magnitude readout and far cheaper than the
        // 100 Hz default — the sampling-rate tradeoff from Course 3.3.
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let a = motion?.userAcceleration else { return }
            self?.accelerationMagnitude = (a.x * a.x + a.y * a.y + a.z * a.z).squareRoot()
        }
    }
}
