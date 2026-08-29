#if os(watchOS)
import Foundation
import HealthKit
import Observation

@MainActor
@Observable
public final class WorkoutSessionManager: NSObject {
    public private(set) var isWorkoutInProgress = false
    public private(set) var heartRate: Double = 0
    public private(set) var activeEnergyKcal: Double = 0
    public private(set) var distanceMeters: Double = 0
    public private(set) var startDate: Date?
    
    // Called when a session ends with the assembled record
    public var onFinish: ((WorkoutRecord) -> Void)?
    
    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    
    public override init() { super.init() }
    
    public var elapsed: TimeInterval {
        guard let startDate else { return 0 }
        return Date().timeIntervalSince(startDate)
    }
    
    public func start(activity: HKWorkoutActivityType = .walking) {
        guard !isWorkoutInProgress else { return }
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activity
        configuration.locationType = .outdoor
        
        do {
            let session = try HKWorkoutSession(healthStore: store, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: configuration)
            
            session.delegate = self
            builder.delegate = self
            
            self.builder = builder
            self.session = session
            
            let now = Date()
            session.startActivity(with: now)
            builder.beginCollection(withStart: now) { [weak self] completion, error in
                Task { @MainActor in
                    self?.isWorkoutInProgress = true
                    self?.startDate = now
                }
            }
        } catch {
            isWorkoutInProgress = false
        }
    }
    
    public func end() {
        guard let session, let builder else { return }
        
        let end = Date()
        builder.endCollection(withEnd: end) { [weak self] _, _  in
            builder.finishWorkout() { _, _ in
                Task { @MainActor in self?.finalize(end: end) }
            }
        }
    }
        
    public func finalize(end: Date) {
        let record = WorkoutRecord(
            start: startDate ?? end,
            end: end,
            activeEnergyKcal: activeEnergyKcal,
            distanceMeters: distanceMeters,
            averageHeartRate: heartRate > 0 ? heartRate : nil
        )
        isWorkoutInProgress = false
        onFinish?(record)
        session = nil
        builder = nil
    }
}

extension WorkoutSessionManager: HKWorkoutSessionDelegate {
    nonisolated public func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        Task { @MainActor in self.isWorkoutInProgress = (toState == .running) }
    }

    nonisolated public func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: any Error
    ) {
        Task { @MainActor in self.isWorkoutInProgress = false }
    }
}

extension WorkoutSessionManager: HKLiveWorkoutBuilderDelegate {
    nonisolated public func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
    
    nonisolated public func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
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
