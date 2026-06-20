//
//  TrailMarkComplication.swift
//  TrailMarkComplication (watchOS Widget Extension)
//
//  Course 3.4 — a WidgetKit complication that surfaces today's headline metric
//  (steps) on the watch face and in the Smart Stack.
//
//  This file is the ENTIRE source for a watchOS Widget Extension target. Because
//  an app-extension target can't be added safely by editing the project file by
//  hand, create the target from Xcode's template and then replace its generated
//  source with this file. See Docs/MANUAL_SETUP.md → "Complication target".
//
//  Live data: the complication reads today's steps from a shared App Group so it
//  can show the same number as the app. Until the App Group is configured it
//  falls back to a sample value, so the widget still previews and runs.
//

import WidgetKit
import SwiftUI

// MARK: - Shared value

/// Reads/writes today's step count through an App Group both the app and the
/// widget can see. Configure the group in MANUAL_SETUP, or leave it for samples.
enum ComplicationData {
    static let appGroup = "group.ramsesg.TrailMark"
    static let stepsKey = "today.steps"

    static var steps: Int {
        UserDefaults(suiteName: appGroup)?.integer(forKey: stepsKey) ?? 0
    }

    /// Call from the app (e.g. after refreshing HealthKit) to publish the value.
    static func publish(steps: Int) {
        UserDefaults(suiteName: appGroup)?.set(steps, forKey: stepsKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Timeline

struct StepsEntry: TimelineEntry {
    let date: Date
    let steps: Int
}

struct StepsProvider: TimelineProvider {
    func placeholder(in context: Context) -> StepsEntry {
        StepsEntry(date: Date(), steps: 6_240)
    }

    func getSnapshot(in context: Context, completion: @escaping (StepsEntry) -> Void) {
        let steps = context.isPreview ? 6_240 : max(ComplicationData.steps, 0)
        completion(StepsEntry(date: Date(), steps: steps))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StepsEntry>) -> Void) {
        let entry = StepsEntry(date: Date(), steps: ComplicationData.steps)
        // Refresh roughly every 15 minutes; the app also force-reloads on update.
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Views (one layout per supported complication family)

struct TrailMarkComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: StepsEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            Text("\(entry.steps) steps")

        case .accessoryCircular:
            Gauge(value: min(Double(entry.steps), 10_000), in: 0...10_000) {
                Image(systemName: "figure.walk")
            } currentValueLabel: {
                Text("\(entry.steps / 1000)k")
            }
            .gaugeStyle(.accessoryCircular)

        case .accessoryCorner:
            Text("\(entry.steps)")
                .widgetCurvesContent()
                .widgetLabel("Steps")

        default: // .accessoryRectangular
            VStack(alignment: .leading) {
                Label("Steps today", systemImage: "figure.walk")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                Text("\(entry.steps)")
                    .font(.system(.title2, design: .rounded, weight: .bold))
            }
        }
    }
}

// MARK: - Widget

@main
struct TrailMarkComplication: Widget {
    let kind = "TrailMarkComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StepsProvider()) { entry in
            TrailMarkComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Steps")
        .description("Today's step count.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCorner
        ])
    }
}
