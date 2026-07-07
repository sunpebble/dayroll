import SwiftUI
import Charts

struct StatsView: View {
    let entries: [Entry]

    private struct MonthStat: Identifiable {
        let month: Date
        let logged: Int
        let avgMood: Double?
        var id: Date { month }
    }

    /// Last 12 months, oldest first; months with no entries stay in as gaps.
    private var monthlyStats: [MonthStat] {
        let calendar = Calendar.current
        let thisMonth = calendar.dateInterval(of: .month, for: .now)!.start
        let byMonth = Dictionary(grouping: entries) { calendar.dateInterval(of: .month, for: $0.day)!.start }
        return (0..<12).reversed().map { back in
            let month = calendar.date(byAdding: .month, value: -back, to: thisMonth)!
            let list = byMonth[month] ?? []
            let scores = list.compactMap { $0.mood?.score }
            return MonthStat(
                month: month,
                logged: list.count,
                avgMood: scores.isEmpty ? nil : Double(scores.reduce(0, +)) / Double(scores.count)
            )
        }
    }

    private var moodCounts: [(mood: Mood, count: Int)] {
        Mood.allCases.map { mood in
            (mood, entries.count { $0.mood == mood })
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("YOUR TAPE, COUNTED")
                    .font(Tape.font(16, weight: .bold))
                    .kerning(3)
                    .padding(.top, 32)

                HStack {
                    Text("TOTAL: \(entries.count)")
                    Spacer()
                    Text("STREAK: \(DataStore.streak(days: entries.map(\.day)))")
                    Spacer()
                    Text("BEST: \(DataStore.longestStreak(days: entries.map(\.day)))")
                }
                .font(Tape.font(12, weight: .semibold))
                .foregroundStyle(Tape.faded)

                section("DAYS LOGGED — LAST 12 MONTHS") {
                    Chart(monthlyStats) { item in
                        BarMark(
                            x: .value("Month", item.month, unit: .month),
                            y: .value("Days", item.logged)
                        )
                        .foregroundStyle(Tape.ink)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month, count: 2)) {
                            AxisValueLabel(format: .dateTime.month(.narrow))
                        }
                    }
                    .frame(height: 150)
                }

                section("MOOD TREND — LAST 12 MONTHS") {
                    Chart(monthlyStats.filter { $0.avgMood != nil }) { item in
                        LineMark(
                            x: .value("Month", item.month, unit: .month),
                            y: .value("Mood", item.avgMood!)
                        )
                        PointMark(
                            x: .value("Month", item.month, unit: .month),
                            y: .value("Mood", item.avgMood!)
                        )
                    }
                    .foregroundStyle(Tape.ink)
                    .chartYScale(domain: 0.5...5.5)
                    .chartYAxis {
                        AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                            AxisValueLabel {
                                if let score = value.as(Int.self) {
                                    Text(Mood.allCases.first { $0.score == score }?.emoji ?? "")
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month, count: 2)) {
                            AxisValueLabel(format: .dateTime.month(.narrow))
                        }
                    }
                    .frame(height: 150)
                }

                section("MOOD MIX — ALL TIME") {
                    Chart(moodCounts, id: \.mood) { item in
                        BarMark(
                            x: .value("Mood", item.mood.emoji),
                            y: .value("Days", item.count)
                        )
                        .foregroundStyle(Tape.ink)
                    }
                    .frame(height: 150)
                }
            }
            .padding(24)
        }
        .background(Tape.paper)
        .foregroundStyle(Tape.ink)
        .presentationDetents([.large])
    }

    private func section(_ title: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 12) {
            Perforation()
            Text(title)
                .font(Tape.font(11, weight: .bold))
                .kerning(1.5)
                .foregroundStyle(Tape.faded)
                .frame(maxWidth: .infinity, alignment: .leading)
            content()
        }
    }
}
