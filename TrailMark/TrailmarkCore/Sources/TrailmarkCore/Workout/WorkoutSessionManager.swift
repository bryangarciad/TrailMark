//
//  WorkoutSessionManager.swift
//  TrailmarkCore
//
//  Course 3.2 — a live workout session on the watch. HKWorkoutSession +
//  HKLiveWorkoutBuilder stream metrics and keep the app running in the
//  background during an activity; the finished workout is saved to HealthKit.
//
//  HKWorkoutSession is watchOS-only, so the whole type is gated to watchOS.
//  The iOS side consumes the *result* (a WorkoutRecord) over connectivity.
//

#if os(watchOS)
import Foundation
import HealthKit
import Observation

@MainActor
@Observable
public final class WorkoutSessionManager: NSObject {

    public private(set) var isRunning = false
    public private(set) var heartRate: Double = 0
    public private(set) var activeEnergyKcal: Double = 0
    public private(set) var distanceMeters: Double = 0
    public private(set) var startDate: Date?

    /// Called when a session ends with the assembled record (for connectivity sync).
    public var onFinish: ((WorkoutRecord) -> Void)?

    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    public override init() { super.init() }

    public var elapsed: TimeInterval {
        guard let startDate else { return 0 }
        return Date().timeIntervalSince(startDate)
    }

    // MARK: - Lifecycle

    public func start(activity: HKWorkoutActivityType = .walking) {
        guard !isRunning else { return }
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activity
        configuration.locationType = .outdoor

        do {
            let session = try HKWorkoutSession(healthStore: store, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: configuration)

            session.delegate = self
            builder.delegate = self

            self.session = session
            self.builder = builder

            let now = Date()
            session.startActivity(with: now)
            builder.beginCollection(withStart: now) { [weak self] _, _ in
                Task { @MainActor in
                    self?.isRunning = true
                    self?.startDate = now
                }
            }
        } catch {
            isRunning = false
        }
    }

    public func end() {
        guard let session, let builder else { return }
        let end = Date()
        session.end()
        builder.endCollection(withEnd: end) { [weak self] _, _ in
            builder.finishWorkout { _, _ in
                Task { @MainActor in self?.finalize(end: end) }
            }
        }
    }

    private func finalize(end: Date) {
        let record = WorkoutRecord(
            start: startDate ?? end,
            end: end,
            activeEnergyKcal: activeEnergyKcal,
            distanceMeters: distanceMeters,
            averageHeartRate: heartRate > 0 ? heartRate : nil
        )
        isRunning = false
        onFinish?(record)
        session = nil
        builder = nil
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WorkoutSessionManager: HKWorkoutSessionDelegate {
    nonisolated public func workoutSession(_ workoutSession: HKWorkoutSession,
                                           didChangeTo toState: HKWorkoutSessionState,
                                           from fromState: HKWorkoutSessionState,
                                           date: Date) {
        Task { @MainActor in
            self.isRunning = (toState == .running)
        }
    }

    nonisolated public func workoutSession(_ workoutSession: HKWorkoutSession,
                                           didFailWithError error: Error) {
        Task { @MainActor in self.isRunning = false }
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension WorkoutSessionManager: HKLiveWorkoutBuilderDelegate {
    nonisolated public func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    nonisolated public func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                                           didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType,
                  let statistics = workoutBuilder.statistics(for: quantityType) else { continue }

            switch quantityType {
            case HKQuantityType(.heartRate):
                let unit = HKUnit.count().unitDivided(by: .minute())
                let bpm = statistics.mostRecentQuantity()?.doubleValue(for: unit) ?? 0
                Task { @MainActor in self.heartRate = bpm }

            case HKQuantityType(.activeEnergyBurned):
                let kcal = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                Task { @MainActor in self.activeEnergyKcal = kcal }

            case HKQuantityType(.distanceWalkingRunning):
                let meters = statistics.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                Task { @MainActor in self.distanceMeters = meters }

            default:
                break
            }
        }
    }
}
#endif
