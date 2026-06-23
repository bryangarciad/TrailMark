//
//  TrailMarkComplication.swift
//  TrailMarkComplication
//
//  Course 3.4 — a WidgetKit complication that surfaces today's step count on the
//  watch face and in the Smart Stack. It reads the value the watch app writes to
//  the shared App Group (group.ramsesg.TrailMark → "today.steps"); if the group
//  isn't configured yet it falls back to a sample so the widget still previews.
//
//  Note: @main lives in TrailMarkComplicationBundle.swift, so this Widget does
//  NOT carry @main itself.
//

import WidgetKit
import SwiftUI

// MARK: - Shared value (App Group)

/// Reads today's steps from the App Group the watch app publishes to.
enum ComplicationData {
    static let appGroup = "group.ramsesg.TrailMark"
    static let stepsKey = "today.steps"

    static var steps: Int {
        UserDefaults(suiteName: appGroup)?.integer(forKey: stepsKey) ?? 0
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
        // Show a sample in the gallery preview; the live value otherwise.
        let steps = context.isPreview ? 6_240 : max(ComplicationData.steps, 0)
        completion(StepsEntry(date: Date(), steps: steps))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StepsEntry>) -> Void) {
        let entry = StepsEntry(date: Date(), steps: ComplicationData.steps)
        // Refresh roughly every 15 min; the app also force-reloads when steps update.
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - View (adapts to each complication family)

struct TrailMarkComplicationEntryView: View {
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
                Text(shortSteps)
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

    private var shortSteps: String {
        entry.steps >= 1000 ? "\(entry.steps / 1000)k" : "\(entry.steps)"
    }
}

// MARK: - Widget

struct TrailMarkComplication: Widget {
    let kind = "TrailMarkComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StepsProvider()) { entry in
            TrailMarkComplicationEntryView(entry: entry)
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

#Preview(as: .accessoryRectangular) {
    TrailMarkComplication()
} timeline: {
    StepsEntry(date: .now, steps: 6_240)
    StepsEntry(date: .now, steps: 8_120)
}
