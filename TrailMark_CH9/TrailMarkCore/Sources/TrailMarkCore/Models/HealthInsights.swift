import Foundation

public struct SleepSummary: Equatable, Sendable, Codable {
    public var asleepSeconds: TimeInterval
    public var date: Date
    
    public init(asleepSeconds: TimeInterval = 0, date: Date = Date()) {
        self.asleepSeconds = asleepSeconds
        self.date = date
    }
    
    public static let empty = SleepSummary()
}

public struct EnergyTrendPoint: Equatable, Sendable, Codable, Identifiable {
    public var id: Date { day }
    
    public var day: Date
    public var activeEnergyKcal: Double
    
    public init(day: Date, activeEnergyKcal: Double) {
        self.day = day
        self.activeEnergyKcal = activeEnergyKcal
    }
}

public struct LiveVitals: Equatable, Sendable, Codable {
    public var heartRateBPM: Double
    public var steps: Double
    public var activeEnergyKcal: Double
    
    public init(heartRateBPM: Double = 0, steps: Double = 0, activeEnergyKcal: Double = 0) {
        self.heartRateBPM = heartRateBPM
        self.steps = steps
        self.activeEnergyKcal = activeEnergyKcal
    }
    
    public static let empty = LiveVitals()
}

public struct ActivitySummary: Equatable, Sendable, Codable {
    public var steps: Double
    public var distanceMeters: Double
    public var activeEnergyKcal: Double
    public var date: Date
    
    public init(steps: Double = 0, distanceMeters: Double = 0, activeEnergyKcal: Double = 0, date: Date = Date()) {
        self.steps = steps
        self.distanceMeters = distanceMeters
        self.activeEnergyKcal = activeEnergyKcal
        self.date = date
    }
    
    public static let empty = ActivitySummary()
}
