import Foundation

public struct SleepSummary: Equatable, Sendable, Codable {
    public var asleepSeconds: TimeInterval
    public var date: Date
    
    public init(asleepSeconds: TimeInterval = 0, date: Date = Date()) {
        self.asleepSeconds = asleepSeconds
        self.date = date
    }
    
    public static let empty = SleepSummary()

    public var hours: Double { asleepSeconds / 3600 }

    public var durationText: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .short
        return formatter.string(from: asleepSeconds) ?? "—"
    }
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

    public var heartRateText: String {
        heartRateBPM > 0 ? "\(Int(heartRateBPM.rounded()))" : "—"
    }
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
    
    public var stepsText: String {
        Self.wholeNumber.string(from: NSNumber(value: steps)) ?? "0"
    }
    
    public var activeEnergyText: String {
        let value = Self.wholeNumber.string(from: NSNumber(value: activeEnergyKcal)) ?? "0"
        return "\(value) k cal"
    }
    
    public var distanceText: String {
        let f = MeasurementFormatter()
        f.unitOptions = .naturalScale
        f.numberFormatter.maximumFractionDigits = 2
        let measurement = Measurement(value: distanceMeters, unit: UnitLength.meters)
        return f.string(from: measurement)
    }
    
    private static let wholeNumber: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()
}
