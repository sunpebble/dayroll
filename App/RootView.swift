import SwiftUI
import SwiftData
import UserNotifications

struct RootView: View {
    @Environment(ProStore.self) private var pro
    @Query(sort: \Entry.day, order: .reverse) private var entries: [Entry]

    private struct ComposeTarget: Identifiable {
        let day: Date
        var id: Date { day }
    }

    private enum PaywallIntent { case stats, export }

    @State private var composeTarget: ComposeTarget?
    @State private var showPaywall = false
    @State private var paywallIntent = PaywallIntent.stats
    @State private var showStats = false
    @State private var showExportDialog = false
    @State private var exportFormat = DataStore.ExportFormat.text
    @State private var showExport = false
    @State private var showReminder = false

    private var streak: Int { DataStore.streak(days: entries.map(\.day)) }

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
                            showReminder = true
                        } label: {
                            Image(systemName: "bell")
                        }
                        Button {
                            if pro.isPro {
                                showStats = true
                            } else {
                                paywallIntent = .stats
                                showPaywall = true
                            }
                        } label: {
                            Image(systemName: "chart.bar")
                        }
                        exportButton
                    }
                }
                .toolbarBackground(Tape.paper, for: .navigationBar)
                .sheet(item: $composeTarget) { target in ComposeView(day: target.day) }
                .sheet(isPresented: $showPaywall, onDismiss: {
                    // 购买/恢复成功后续接用户原本想做的事,而不是干等着再点一次
                    guard pro.isPro else { return }
                    switch paywallIntent {
                    case .stats: showStats = true
                    case .export: showExportDialog = true
                    }
                }) { PaywallView() }
                .sheet(isPresented: $showStats) { StatsView(entries: entries) }
                .sheet(isPresented: $showReminder) {
                    ReminderSheet()
                        .presentationDetents([.height(220)])
                }
                .sheet(isPresented: $showExport) {
                    ActivityView(text: exportText)
                        .presentationDetents([.medium])
                }
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
    }

    private var exportButton: some View {
        Button {
            if pro.isPro {
                showExportDialog = true
            } else {
                paywallIntent = .export
                showPaywall = true
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .confirmationDialog("Export format", isPresented: $showExportDialog, titleVisibility: .visible) {
            ForEach(DataStore.ExportFormat.allCases) { format in
                Button(LocalizedStringKey(format.rawValue)) {
                    exportFormat = format
                    showExport = true
                }
            }
        }
    }

    private var exportText: String {
        DataStore.export(entries, as: exportFormat)
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
        .accessibilityIdentifier("log")
    }
}

// resume the export after purchase — so export goes through UIActivityViewController
private struct ActivityView: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

/// Daily "one line about today?" nudge. A repeating calendar trigger — it fires
/// whether or not today is already logged; rescheduling per-day isn't worth it.
struct ReminderSheet: View {
    @AppStorage("reminderEnabled") private var enabled = false
    @AppStorage("reminderMinutes") private var minutes = 21 * 60  // 21:00

    private static let notificationID = "daily-reminder"

    private var time: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60,
                                      second: 0, of: .now) ?? .now
            },
            set: {
                let comps = Calendar.current.dateComponents([.hour, .minute], from: $0)
                minutes = comps.hour! * 60 + comps.minute!
            }
        )
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("DAILY REMINDER")
                .font(Tape.font(14, weight: .bold))
                .kerning(3)
                .padding(.top, 28)
            Perforation()
            Toggle(isOn: $enabled) {
                Text("REMIND ME TO LOG")
                    .font(Tape.font(12, weight: .semibold))
                    .kerning(1)
            }
            .tint(Tape.ink)
            if enabled {
                DatePicker("Time", selection: time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .foregroundStyle(Tape.ink)
        .background(Tape.paper)
        .onChange(of: enabled) { sync() }
        .onChange(of: minutes) { sync() }
    }

    private func sync() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.notificationID])
        guard enabled else { return }
        Task {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        }
        let content = UNMutableNotificationContent()
        content.title = "Dayroll"
        content.body = String(localized: "One line about today?")
        content.sound = .default
        var comps = DateComponents()
        comps.hour = minutes / 60
        comps.minute = minutes % 60
        center.add(UNNotificationRequest(
            identifier: Self.notificationID,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)))
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
