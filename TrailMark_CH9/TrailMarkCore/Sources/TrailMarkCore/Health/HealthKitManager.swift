import Foundation
import HealthKit
import Observation

@MainActor
@Observable
public final class HealthKitManager {
    
    public enum AuthorizationState: Equatable {
        case unknown
        case unavailable
        case requesting
        case authorized
        case denied
    }
    
    public private(set) var authorizationStatus: AuthorizationState = .unknown
    
    public private(set) var todaySummary: ActivitySummary = .empty // steps, distanceMeters, activeEnergyKcal (hkSampleQuery)
    public private(set) var sleep: SleepSummary = .empty // asleepSeconds (hkSampleQuery)
    public private(set) var energyTrend: [EnergyTrendPoint] = [] // activeEnergyKcal (hkStatics)
    public private(set) var liveVital: LiveVitals = .empty // hearthRate, steps, activeEnergyKcal (real time continuous)
    
    private let store = HKHealthStore()
    private var liveQueries: [HKQuery] = []
    
    public init() {
        if !HKHealthStore.isHealthDataAvailable() {
            authorizationStatus = .unavailable
        }
    }
    
    // MARK: - Activity Summary
    public func refreshToday() async {
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
    
    public func sumQuantity(_ type: HKQuantityType, unit: HKUnit, since start: Date) async -> Double {
        guard authorizationStatus == .authorized else { return 0.0 }
        
        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
            
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { query, stats, _ in
                let value = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            
            store.execute(query)
        }
    }
    
    // MARK: - All Health Data Type That The App Interacts With
    private var stepType: HKQuantityType { HKQuantityType(.stepCount) }
    private var distanceType: HKQuantityType { HKQuantityType(.distanceWalkingRunning) }
    private var energyType: HKQuantityType { HKQuantityType(.activeEnergyBurned) }
    private var sleepType: HKCategoryType { HKCategoryType(.sleepAnalysis) }
    private var hearthRateType: HKQuantityType { HKQuantityType(.heartRate) }
    
    private var readTypes: Set<HKObjectType> {
        [stepType, distanceType, energyType, hearthRateType, sleepType, HKObjectType.workoutType()]
    }
    
    private var shareTypes: Set<HKSampleType> {
        [energyType, distanceType, HKObjectType.workoutType()]
    }
    
    public func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = .unavailable
            return
        }
        
        authorizationStatus = .requesting
        
        do {
            try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
            // Note: for privacy ios never tells us wheter read access was granted
            // we treat request completed as authorized and let zeored summary stand for the denied empty case
            authorizationStatus = .authorized
            
        } catch {
            authorizationStatus = .denied
        }
    }
    
    
    // MARK: - Sleep Data Query
    public func refreshLastNightSleep() async {
        guard authorizationStatus == .authorized else { return }
        
        // Create the time windows for last night (time windows (StarDate To EndDate) -> time predicate)
        let calendar = Calendar.current
        let now = Date()
        
        // windows: 6pm yestarday -> noon today, which brackets a normal night
        let noonToday = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now) ?? now
        let sixPmYesterday = calendar.date(byAdding: .hour, value: -18, to: noonToday) ?? now
        
        let samples: [HKCategorySample] = await withCheckedContinuation { continuation in
            // This is the time predicate (start and end date)
            let predicate = HKQuery.predicateForSamples(withStart: sixPmYesterday, end: noonToday)
            
            // This is the actual query
            let query  = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, results, _ in // results is an [HKSample];
                continuation.resume(returning: (results as? [HKCategorySample]) ?? [])
            }
            
            store.execute(query)
        }
        
        // Procesing Data Part
        // [HKCategorySample] -> SleepSummary
        // Category Types are Enums (They have a defined set of options)
        
        // These options are the 4 sleep statuses that we recognize as valid sleeping status
        let asleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
        ]
        
        let total = samples
            .filter { asleepValues.contains($0.value) }
            .reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
        
        self.sleep = SleepSummary(asleepSeconds: total, date: calendar.startOfDay(for: now))
    }
    
    // We want to calculate a 7 days active energy trend (monday: AET (Avg), Tuesday: AET (Avg))
    public func refreshEnergyTrend() async {
        guard authorizationStatus == .authorized else { return }
        let calendar = Calendar.current
        let endDay = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -6 , to: endDay) else { return }
        
        let trend: [EnergyTrendPoint] = await withCheckedContinuation { continuation in
            var interval = DateComponents()
            interval.day = 1
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDay)
            let query = HKStatisticsCollectionQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage,
                anchorDate: startDate,
                intervalComponents: interval
            )
            query.initialResultsHandler = { query, collection, error in
                var points: [EnergyTrendPoint] = []
                collection?.enumerateStatistics(from: startDate, to: Date()) { stats, _ in
                    let kcal = stats.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                    points.append(EnergyTrendPoint(day: stats.startDate, activeEnergyKcal: kcal))
                }
                continuation.resume(returning: points)
            }
            store.execute(query)
        }
        self.energyTrend = trend
    }
    
    // TODO: Create this func
    public func refreshEnergyTrendWithHKSampleQuery() async {
        guard authorizationStatus == .authorized else { return }
        let calendar = Calendar.current
        
        let today = calendar.startOfDay(for: Date())
        
        guard let startDate = calendar.date(byAdding: .day, value: -6, to: today),
              let endDate = calendar.date(byAdding: .day, value: 1, to: today ) else { return }
        
        let samples: [HKQuantitySample] = await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
            
            let query = HKSampleQuery(
                sampleType: energyType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { query, results, error in
                continuation.resume(returning: (results as? [HKQuantitySample]) ?? [])
            }
        }
        
        var totals: [Date: Double] = [:]
        for sample in samples {
            let day = calendar.startOfDay(for: sample.startDate)
            totals[day, default: 0] += sample.quantity.doubleValue(for: .kilocalorie())
        }
        
        self.energyTrend = (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: startDate) else { return nil }
            return EnergyTrendPoint(day: day, activeEnergyKcal: totals[day] ?? 0)
        }
    }
    
    
    // MARK: - Write A Workout

    /// Saves a finished activity to HealthKit as an `HKWorkout` using `HKWorkoutBuilder`.
    /// Once this returns the workout shows up in the Health app.
    public func save(_ record: WorkoutRecord, activity: HKWorkoutActivityType = .walking) async throws {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activity

        let builder = HKWorkoutBuilder(healthStore: store, configuration: configuration, device: .local())

        try await builder.beginCollection(at: record.start)

        // The builder only stores totals if we hand it the samples that back them.
        var samples: [HKSample] = []
        if record.activeEnergyKcal > 0 {
            let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: record.activeEnergyKcal)
            samples.append(
                HKCumulativeQuantitySample(
                    type: energyType,
                    quantity: quantity,
                    start: record.start,
                    end: record.end
                )
            )
        }
        if record.distanceMeters > 0 {
            let quantity = HKQuantity(unit: .meter(), doubleValue: record.distanceMeters)
            samples.append(
                HKCumulativeQuantitySample(
                    type: distanceType,
                    quantity: quantity,
                    start: record.start,
                    end: record.end
                )
            )
        }
        if !samples.isEmpty {
            try await builder.addSamples(samples)
        }

        try await builder.endCollection(at: record.end)
        _ = try await builder.finishWorkout()
    }


    // MARK: - Live Vitals

    public func startLiveVitals() {
        startHeartRateStream() // It will get heart rate real time and assign the value to the live vitals struct
        Task {
            await refreshTodaysVitals() // async it will try to fill energy and steps (not real time)
        }
    }
    
    public func stopLiveVitals() {
        liveQueries.forEach { store.stop($0) }
        liveQueries.removeAll()
    }
    
    public func startHeartRateStream() {
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: nil)
        
        let dataHandler: @Sendable (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void =
        { [weak self] _, samples, _, _, _ in
            guard let latest = (samples as? [HKQuantitySample])?.last else { return }
            
            let bpm = latest.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            
            Task { @MainActor in
                self?.liveVital.heartRateBPM = bpm
            }
        }
        
        // Web Sockets
        let query = HKAnchoredObjectQuery(
            type: hearthRateType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit,
            resultsHandler: dataHandler // First execution handler
        )
        query.updateHandler = dataHandler // Update Handler (every time except the first)
        
        store.execute(query)
        liveQueries.append(query)
    }
    
    // one shot refresh today steps plus energy used by the live vitals struct
    public func refreshTodaysVitals() async {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        async let steps = sumQuantity(stepType, unit: .count(), since: startOfDay)
        async let energy = sumQuantity(energyType, unit: .kilocalorie(), since: startOfDay)
        liveVital.steps = await steps
        liveVital.activeEnergyKcal = await energy
    }
}
