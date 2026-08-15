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
    
    // MARK: - All Health Data Type That The App Interacts With
    private var stepType: HKQuantityType { HKQuantityType(.stepCount) }
    private var distanceType: HKQuantityType { HKQuantityType(.distanceWalkingRunning) }
    private var energyType: HKQuantityType { HKQuantityType(.activeEnergyBurned) }
    private var sleepType: HKCategoryType { HKCategoryType(.sleepAnalysis) }
    private var hearthRateType: HKQuantityType { HKQuantityType(.heartRate) }
    
    private var readTypes: Set<HKObjectType> {
        [stepType, distanceType, energyType, hearthRateType, HKObjectType.workoutType()]
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
            ) { [weak self] query, results, error in // results is an [HKSample];
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
        
    }
    
}
