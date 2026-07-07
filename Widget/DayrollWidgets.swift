import SwiftUI
import SwiftData
import WidgetKit

@main
struct DayrollWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayWidget()
        AccessoryWidget()
    }
}

// MARK: - Timeline

struct TapeSnapshot: TimelineEntry {
    let date: Date
    let mood: Mood?
    let line: String
    let streak: Int
    let total: Int

    static let placeholder = TapeSnapshot(date: .now, mood: .good, line: "Coffee with Anna.", streak: 4, total: 23)
}

// Free function: inside Provider, `Entry` would resolve to TimelineProvider's
// associated type (TapeSnapshot), shadowing the SwiftData model.
private func fetchSnapshot() -> TapeSnapshot {
    let context = ModelContext(DataStore.container)
    let descriptor = FetchDescriptor<Entry>(sortBy: [SortDescriptor(\.day, order: .reverse)])
    let entries = (try? context.fetch(descriptor)) ?? []
    let today = entries.first { Calendar.current.isDateInToday($0.day) }
    return TapeSnapshot(
        date: .now,
        mood: today?.mood,
        line: today?.line ?? "",
        streak: DataStore.streak(days: entries.map(\.day)),
        total: entries.count
    )
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TapeSnapshot { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (TapeSnapshot) -> Void) {
        completion(context.isPreview ? .placeholder : fetchSnapshot())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TapeSnapshot>) -> Void) {
        let midnight = Calendar.current.startOfDay(for: .now.addingTimeInterval(86400))
        completion(Timeline(entries: [fetchSnapshot()], policy: .after(midnight)))
    }
}

// MARK: - Home screen widget (interactive mood tap)

struct TodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TodayWidget", provider: Provider()) { snapshot in
            TodayWidgetView(snapshot: snapshot)
                .containerBackground(Tape.paper, for: .widget)
        }
        .configurationDisplayName("Today's Line")
        .description("Log your mood with one tap.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct TodayWidgetView: View {
    let snapshot: TapeSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("DAYROLL")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .kerning(2)
                Spacer()
                Text(Date.now.formatted(.dateTime.month(.abbreviated).day()).uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            if let mood = snapshot.mood {
                Link(destination: URL(string: "dayroll://compose")!) {
                    HStack(spacing: 6) {
                        Text(mood.emoji).font(.system(size: 18))
                        Group {
                            if snapshot.line.isEmpty {
                                Text("Add one line…")
                            } else {
                                Text(snapshot.line)
                            }
                        }
                        .font(.system(size: 12, design: .monospaced))
                        .lineLimit(2)
                        .foregroundStyle(snapshot.line.isEmpty ? .secondary : .primary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            } else {
                HStack(spacing: 4) {
                    ForEach(Mood.allCases, id: \.self) { mood in
                        Button(intent: LogMoodIntent(mood: mood)) {
                            Text(mood.emoji)
                                .font(.system(size: 16))
                                .frame(maxWidth: .infinity, minHeight: 30)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Text("STREAK: \(snapshot.streak)")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(Tape.ink)
    }
}

// MARK: - Lock screen widgets (fast deep link into compose)

struct AccessoryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "AccessoryWidget", provider: Provider()) { snapshot in
            AccessoryView(snapshot: snapshot)
                .containerBackground(.clear, for: .widget)
                .widgetURL(URL(string: "dayroll://compose")!)
        }
        .configurationDisplayName("Log Today")
        .description("One tap from your Lock Screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct AccessoryView: View {
    @Environment(\.widgetFamily) private var family
    let snapshot: TapeSnapshot

    var body: some View {
        switch family {
        case .accessoryCircular:
            VStack(spacing: 0) {
                Text(snapshot.mood?.emoji ?? "✏️").font(.system(size: 16))
                Text("\(snapshot.streak)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
            }
        case .accessoryInline:
            if snapshot.mood == nil {
                Text("Dayroll: log today")
            } else {
                Text("Dayroll ✓ \(snapshot.streak)d")
            }
        default:
            VStack(alignment: .leading, spacing: 2) {
                Text("DAYROLL")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                Group {
                    if snapshot.mood == nil {
                        Text("Tap to log today")
                    } else if snapshot.line.isEmpty {
                        Text("\(snapshot.mood!.emoji) Add one line…")
                    } else {
                        Text("\(snapshot.mood!.emoji) \(snapshot.line)")
                    }
                }
                .font(.system(size: 11, design: .monospaced))
                .lineLimit(2)
            }
        }
    }
}
