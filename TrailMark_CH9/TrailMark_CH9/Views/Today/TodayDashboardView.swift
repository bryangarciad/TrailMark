import SwiftUI
import TrailMarkCore

struct TodayDashboardView: View {
    @Environment(AppModel.self) private var model
    
    var body: some View {
        NavigationStack {
            Group {
                switch model.health.authorizationStatus {
                case .unavailable:
                    ContentUnavailableView(
                        "Health data is unavailable",
                        systemImage: "hearth.slash",
                        description: Text("The device can't provide Health data.")
                    )
                case .denied:
                    ContentUnavailableView {
                        Label("Health access needed", systemImage: "lock.fill")
                    } description: {
                        Text("Enable TrailMArk health access")
                    } actions: {
                        Button("Try again") {
                            Task {
                                await model.health.requestAuthorization()
                                await model.health.refreshToday()
                            }
                        }
                    }
                default:
                    summary
                }
            }
            .navigationTitle("Today")
            .task { await model.health.refreshToday() }
            .refreshable {
                await model.health.refreshToday()
            }
        }
    }
    
    private var summary: some View {
        ScrollView {
            VStack(spacing: 16) {
                MetricCard(
                    title: "Steps",
                    value: model.health.todaySummary.stepsText,
                    symbol: "figure.walk",
                    tint: .orange
                )
                MetricCard(
                    title: "Distance",
                    value: model.health.todaySummary.distanceText,
                    symbol: "point.topleft.down.curvedto.point.bottomright.up",
                    tint: .teal
                )
                MetricCard(
                    title: "Active Energy",
                    value: model.health.todaySummary.activeEnergyText,
                    symbol: "flame.fill",
                    tint: .red
                )
            }
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.title)
                .foregroundStyle(tint)
                .frame(width: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .contentTransition(.numericText())
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    TodayDashboardView()
        .environment(AppModel())
}
