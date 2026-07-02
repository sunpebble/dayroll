import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(ProStore.self) private var pro
    @Query(sort: \Entry.day, order: .reverse) private var entries: [Entry]

    private struct ComposeTarget: Identifiable {
        let day: Date
        var id: Date { day }
    }

    @State private var composeTarget: ComposeTarget?
    @State private var showPaywall = false
    @State private var showStats = false

    private var streak: Int { DataStore.streak(days: entries.map(\.day)) }

    // ponytail: @Query loads all entries; fine for years of one-liners, revisit at ~10k
    private var months: [(month: Date, entries: [Entry])] {
        let calendar = Calendar.current
        return Dictionary(grouping: entries) { calendar.dateInterval(of: .month, for: $0.day)!.start }
            .sorted { $0.key > $1.key }
            .map { ($0.key, $0.value) }
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    tape(proxy)
                        .overlay(alignment: .trailing) {
                            if months.count > 1 {
                                MonthIndexStrip(months: months.map(\.month)) { month in
                                    proxy.scrollTo(month, anchor: .top)
                                }
                                .padding(.trailing, 2)
                            }
                        }
                    // ponytail: bar lives outside the ScrollView — .safeAreaInset drifted
                    // the launch scroll offset on iOS 27 beta (compounding across launches)
                    logButton
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Tape.paper)
                        .overlay(alignment: .top) { Perforation() }
                }
                .background(Tape.paper)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            pro.isPro ? (showStats = true) : (showPaywall = true)
                        } label: {
                            Image(systemName: "chart.bar")
                        }
                        exportButton
                    }
                }
                .toolbarBackground(Tape.paper, for: .navigationBar)
                .sheet(item: $composeTarget) { target in ComposeView(day: target.day) }
                .sheet(isPresented: $showPaywall) { PaywallView() }
                .sheet(isPresented: $showStats) { StatsView(entries: entries) }
                .onOpenURL { url in
                    if url.host() == "compose" { composeTarget = ComposeTarget(day: .now) }
                }
                .tint(Tape.ink)
                .onAppear {
                    #if DEBUG
                    if CommandLine.arguments.contains("-showStats") { showStats = true }
                    #endif
                }
            }
        }
    }

    private func tape(_ proxy: ScrollViewProxy) -> some View {
        ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12, pinnedViews: [.sectionHeaders]) {
                        header
                        Perforation()
                        if entries.isEmpty {
                            Text("NO ENTRIES YET\nTAP + TO LOG TODAY")
                                .font(Tape.font(13))
                                .foregroundStyle(Tape.faded)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 48)
                        } else {
                            ForEach(months, id: \.month) { section in
                                Section {
                                    ForEach(section.entries) { entry in
                                        row(entry)
                                    }
                                } header: {
                                    monthHeader(section.month, count: section.entries.count)
                                        .id(section.month)
                                }
                            }
                        }
                        Perforation()
                    }
                    .padding(20)
                    // ponytail: receipts are narrow — cap the tape and center it on iPad
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("DAYROLL")
                .font(Tape.font(22, weight: .bold))
                .kerning(6)
            Text("* ONE LINE A DAY *")
                .font(Tape.font(11))
                .foregroundStyle(Tape.faded)
            HStack {
                Text("TOTAL DAYS: \(entries.count)")
                Spacer()
                Text("STREAK: \(streak)")
            }
            .font(Tape.font(11, weight: .semibold))
            .foregroundStyle(Tape.faded)
            .padding(.top, 10)
        }
        .foregroundStyle(Tape.ink)
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private func monthHeader(_ month: Date, count: Int) -> some View {
        HStack {
            Text(month.formatted(.dateTime.month(.wide).year()).uppercased())
                .kerning(1.5)
            Spacer()
            Text("\(count) DAYS")
        }
        .font(Tape.font(11, weight: .bold))
        .foregroundStyle(Tape.faded)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(Tape.paper)
        .overlay(alignment: .bottom) { Perforation() }
    }

    private func row(_ entry: Entry) -> some View {
        Button {
            composeTarget = ComposeTarget(day: entry.day)
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Text(entry.day.formatted(.dateTime.month(.abbreviated).day(.twoDigits)).uppercased())
                    .font(Tape.font(12, weight: .semibold))
                    .foregroundStyle(Tape.faded)
                    .frame(width: 58, alignment: .leading)
                Text(entry.mood?.emoji ?? "·")
                    .font(.system(size: 14))
                Text(entry.line.isEmpty ? "—" : entry.line)
                    .font(Tape.font(13))
                    .foregroundStyle(Tape.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(TapePressStyle())
        .contextMenu {
            Button {
                composeTarget = ComposeTarget(day: entry.day)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                DataStore.delete(day: entry.day)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private var exportButton: some View {
        if pro.isPro {
            ShareLink(item: exportText) {
                Image(systemName: "square.and.arrow.up")
            }
        } else {
            Button { showPaywall = true } label: {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }

    private var exportText: String {
        entries
            .sorted { $0.day < $1.day }
            .map { entry in
                let date = entry.day.formatted(.iso8601.year().month().day())
                let mood = entry.mood.map { " [\($0.rawValue)]" } ?? ""
                return "\(date)\(mood) \(entry.line)"
            }
            .joined(separator: "\n")
    }

    private var logButton: some View {
        Button { composeTarget = ComposeTarget(day: .now) } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Tape.paper)
                .frame(width: 52, height: 52)
                .background(Circle().fill(Tape.ink))
        }
        .buttonStyle(TapePressStyle())
    }
}

/// Contacts-style index strip: tap or scrub to jump between months.
/// January rows show the two-digit year in bold as the year boundary marker.
struct MonthIndexStrip: View {
    let months: [Date]          // descending, must match the tape's section order
    let onSelect: (Date) -> Void

    @State private var activeIndex: Int?

    var body: some View {
        GeometryReader { geo in
            let rowHeight = min(16, geo.size.height / CGFloat(max(months.count, 1)))
            VStack(spacing: 0) {
                ForEach(months, id: \.self) { month in
                    Text(label(for: month))
                        .font(Tape.font(9, weight: isJanuary(month) ? .bold : .regular))
                        .foregroundStyle(isJanuary(month) ? Tape.ink : Tape.faded)
                        .frame(width: 24, height: rowHeight)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let index = min(max(Int(value.location.y / rowHeight), 0), months.count - 1)
                        if index != activeIndex {
                            activeIndex = index
                            onSelect(months[index])
                        }
                    }
                    .onEnded { _ in activeIndex = nil }
            )
            .sensoryFeedback(.selection, trigger: activeIndex) { _, new in new != nil }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 24)
    }

    private func isJanuary(_ month: Date) -> Bool {
        Calendar.current.component(.month, from: month) == 1
    }

    private func label(for month: Date) -> String {
        isJanuary(month)
            ? month.formatted(.dateTime.year(.twoDigits))
            : month.formatted(.dateTime.month(.narrow))
    }
}
