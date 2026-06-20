//
//  ActivitySummary.swift
//  TrailmarkCore
//
//  Course 1.1 — the "Today" dashboard data.
//

import Foundation

/// A snapshot of the day's headline activity metrics, read from HealthKit.
///
/// Values are plain doubles in their canonical units so the model has no
/// dependency on HealthKit — views and the watch can use it without importing
/// HealthKit at all.
public struct ActivitySummary: Equatable, Sendable, Codable {
    /// Total step count for the day.
    public var steps: Double
    /// Walking + running distance, in meters.
    public var distanceMeters: Double
    /// Active energy burned, in kilocalories.
    public var activeEnergyKcal: Double
    /// The day this summary describes (start of day).
    public var date: Date

    public init(steps: Double = 0,
                distanceMeters: Double = 0,
                activeEnergyKcal: Double = 0,
                date: Date = Date()) {
        self.steps = steps
        self.distanceMeters = distanceMeters
        self.activeEnergyKcal = activeEnergyKcal
        self.date = date
    }

    /// An empty summary — used for the graceful "no data / denied" state.
    public static let empty = ActivitySummary()

    // MARK: Display helpers

    public var stepsText: String {
        Self.wholeNumber.string(from: NSNumber(value: steps)) ?? "0"
    }

    /// Distance formatted in km or mi according to the user's locale.
    public var distanceText: String {
        let measurement = Measurement(value: distanceMeters, unit: UnitLength.meters)
        return Self.distanceFormatter.string(from: measurement)
    }

    public var activeEnergyText: String {
        let value = Self.wholeNumber.string(from: NSNumber(value: activeEnergyKcal)) ?? "0"
        return "\(value) kcal"
    }

    private static let wholeNumber: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()

    private static let distanceFormatter: MeasurementFormatter = {
        let f = MeasurementFormatter()
        f.unitOptions = .naturalScale
        f.numberFormatter.maximumFractionDigits = 2
        return f
    }()
}
