//
//  HealthKitManager.swift
//  TrailmarkCore
//
//  The single HealthKit layer used by BOTH the iOS app and the watch app.
//  Every HealthKit call in the whole project lives here — views never touch
//  HealthKit directly (curriculum 1.1 / 1.3 / 2.3).
//

import Foundation
import HealthKit
import Observation

@MainActor
@Observable
public final class HealthKitManager {

    public enum AuthorizationState: Equatable {
        case unknown
        case unavailable      // device has no Health data (e.g. iPad / some sims)
        case requesting
        case authorized
        case denied
    }

    // MARK: Published state (drives SwiftUI)

    public private(set) var authorization: AuthorizationState = .unknown
    public private(set) var todaySummary: ActivitySummary = .empty
    public private(set) var sleep: SleepSummary = .empty
    public private(set) var energyTrend: [EnergyTrendPoint] = []
    public private(set) var liveVitals: LiveVitals = .empty

    private let store = HKHealthStore()
    private var liveQueries: [HKQuery] = []

    public init() {
        if !HKHealthStore.isHealthDataAvailable() {
            authorization = .unavailable
        }
    }

    // MARK: - Types we touch

    private var stepType: HKQuantityType { HKQuantityType(.stepCount) }
    private var distanceType: HKQuantityType { HKQuantityType(.distanceWalkingRunning) }
    private var energyType: HKQuantityType { HKQuantityType(.activeEnergyBurned) }
    private var heartRateType: HKQuantityType { HKQuantityType(.heartRate) }
    private var sleepType: HKCategoryType { HKCategoryType(.sleepAnalysis) }

    private var readTypes: Set<HKObjectType> {
        [stepType, distanceType, energyType, heartRateType, sleepType, HKObjectType.workoutType()]
    }

    private var shareTypes: Set<HKSampleType> {
        [energyType, distanceType, HKObjectType.workoutType()]
    }

    // MARK: - Authorization (curriculum 1.1)

    /// Requests read + write access. Purpose strings live in the app's Info.plist
    /// (see Docs/MANUAL_SETUP.md) — HealthKit will not show the sheet without them.
    public func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorization = .unavailable
            return
        }
        authorization = .requesting
        do {
            try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
            // Note: for privacy, iOS never tells us whether *read* access was
            // granted. We treat "the request completed" as authorized and let a
            // zeroed summary stand in for the denied/empty case.
            authorization = .authorized
        } catch {
            authorization = .denied
        }
    }

    // MARK: - Today's activity (curriculum 1.1)

    /// Refreshes steps, distance and active energy for today. Safe to call
    /// from `.onAppear`; failures collapse to an empty summary rather than crash.
    public func refreshToday() async {
        guard authorization == .authorized else { return }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        async let steps = sumQuantity(stepType, unit: .count(), since: startOfDay)
        async let distance = sumQuantity(distanceType, unit: .meter(), since: startOfDay)
        async let energy = sumQuantity(energyType, unit: .kilocalorie(), since: startOfDay)

        todaySummary = ActivitySummary(
            steps: await steps,
            distanceMeters: await distance,
            activeEnergyKcal: await energy,
            date: startOfDay
        )
    }

    /// Cumulative sum of a quantity type from `start` to now, using
    /// `HKStatisticsQuery` (the curriculum's named query type).
    private func sumQuantity(_ type: HKQuantityType, unit: HKUnit, since start: Date) async -> Double {
        await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
            let query = HKStatisticsQuery(quantityType: type,
                                          quantitySamplePredicate: predicate,
                                          options: .cumulativeSum) { _, stats, _ in
                let value = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    // MARK: - Sleep (curriculum 1.3)

    /// Reads last night's `sleepAnalysis` samples and sums the "asleep" stages.
    public func refreshLastNightSleep() async {
        guard authorization == .authorized else { return }
        let calendar = Calendar.current
        let now = Date()
        // Window: 6pm yesterday → noon today, which brackets a normal night.
        let noonToday = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now) ?? now
        let sixPMYesterday = calendar.date(byAdding: .hour, value: -18, to: noonToday) ?? now

        let samples: [HKCategorySample] = await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: sixPMYesterday, end: noonToday)
            let query = HKSampleQuery(sampleType: sleepType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: nil) { _, results, _ in
                continuation.resume(returning: (results as? [HKCategorySample]) ?? [])
            }
            store.execute(query)
        }

        let asleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue
        ]
        let total = samples
            .filter { asleepValues.contains($0.value) }
            .reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }

        sleep = SleepSummary(asleepSeconds: total, date: calendar.startOfDay(for: now))
    }

    // MARK: - 7-day active-energy trend (curriculum 1.3)

    /// Builds a daily active-energy collection for the last 7 days using
    /// `HKStatisticsCollectionQuery`, then maps it to chart points.
    public func refreshEnergyTrend() async {
        guard authorization == .authorized else { return }
        let calendar = Calendar.current
        let endDay = calendar.startOfDay(for: Date())
        guard let startDay = calendar.date(byAdding: .day, value: -6, to: endDay) else { return }

        let trend: [EnergyTrendPoint] = await withCheckedContinuation { continuation in
            var interval = DateComponents()
            interval.day = 1
            let predicate = HKQuery.predicateForSamples(withStart: startDay, end: Date())
            let query = HKStatisticsCollectionQuery(quantityType: energyType,
                                                    quantitySamplePredicate: predicate,
                                                    options: .cumulativeSum,
                                                    anchorDate: startDay,
                                                    intervalComponents: interval)
            query.initialResultsHandler = { _, collection, _ in
                var points: [EnergyTrendPoint] = []
                collection?.enumerateStatistics(from: startDay, to: Date()) { stats, _ in
                    let kcal = stats.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                    points.append(EnergyTrendPoint(day: stats.startDate, activeEnergyKcal: kcal))
                }
                continuation.resume(returning: points)
            }
            store.execute(query)
        }
        energyTrend = trend
    }

    // MARK: - Write a workout (curriculum 1.3 / 3.2)

    /// Saves a finished activity to HealthKit as an `HKWorkout` using the modern
    /// `HKWorkoutBuilder`. After this returns the workout appears in the Health app.
    public func save(_ record: WorkoutRecord, activity: HKWorkoutActivityType = .walking) async throws {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activity

        let builder = HKWorkoutBuilder(healthStore: store, configuration: configuration, device: .local())

        try await builder.beginCollection(at: record.start)

        var samples: [HKSample] = []
        if record.activeEnergyKcal > 0 {
            let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: record.activeEnergyKcal)
            samples.append(HKCumulativeQuantitySample(type: energyType,
                                                      quantity: quantity,
                                                      start: record.start,
                                                      end: record.end))
        }
        if record.distanceMeters > 0 {
            let quantity = HKQuantity(unit: .meter(), doubleValue: record.distanceMeters)
            samples.append(HKCumulativeQuantitySample(type: distanceType,
                                                      quantity: quantity,
                                                      start: record.start,
                                                      end: record.end))
        }
        if !samples.isEmpty {
            try await builder.addSamples(samples)
        }

        try await builder.endCollection(at: record.end)
        _ = try await builder.finishWorkout()
    }

    // MARK: - Live vitals (curriculum 2.3)

    /// Starts anchored queries that push heart rate / steps / energy into
    /// `liveVitals` as new samples arrive. Call `stopLiveVitals()` on disappear.
    public func startLiveVitals() {
        guard authorization == .authorized, liveQueries.isEmpty else { return }
        startHeartRateStream()
        Task {
            await refreshTodayVitals()
        }
    }

    public func stopLiveVitals() {
        liveQueries.forEach { store.stop($0) }
        liveQueries.removeAll()
    }

    private func startHeartRateStream() {
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: nil)
        let handler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = { [weak self] _, samples, _, _, _ in
            guard let latest = (samples as? [HKQuantitySample])?.last else { return }
            let bpm = latest.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            Task { @MainActor in
                self?.liveVitals.heartRateBPM = bpm
            }
        }
        let query = HKAnchoredObjectQuery(type: heartRateType,
                                          predicate: predicate,
                                          anchor: nil,
                                          limit: HKObjectQueryNoLimit,
                                          resultsHandler: handler)
        query.updateHandler = handler
        store.execute(query)
        liveQueries.append(query)
    }

    /// One-shot refresh of today's steps + energy used by the live vitals view.
    public func refreshTodayVitals() async {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        async let steps = sumQuantity(stepType, unit: .count(), since: startOfDay)
        async let energy = sumQuantity(energyType, unit: .kilocalorie(), since: startOfDay)
        liveVitals.steps = await steps
        liveVitals.activeEnergyKcal = await energy
    }
}
