import SwiftUI
import SwiftData

struct ComposeView: View {
    private let day: Date

    @Environment(ProStore.self) private var pro
    @Environment(\.dismiss) private var dismiss
    @State private var mood: Mood = .meh
    @State private var line = ""
    @State private var hasEntry = false
    @State private var confirmDelete = false
    @State private var memories: [(yearsAgo: Int, emoji: String?, line: String)] = []
    @FocusState private var focused: Bool

    init(day: Date = .now) {
        self.day = Calendar.current.startOfDay(for: day)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()).uppercased())
                    .font(Tape.font(12, weight: .semibold))
                    .foregroundStyle(Tape.faded)

                HStack(spacing: 16) {
                    ForEach(Mood.allCases, id: \.self) { candidate in
                        Button {
                            mood = candidate
                        } label: {
                            Text(candidate.emoji)
                                .font(.system(size: 32))
                                .opacity(mood == candidate ? 1 : 0.3)
                                .scaleEffect(mood == candidate ? 1.2 : 1)
                        }
                        .buttonStyle(TapePressStyle())
                    }
                }
                .animation(.snappy, value: mood)

                TextField("One line about today…", text: $line, axis: .vertical)
                    .font(Tape.font(15))
                    .focused($focused)
                    .submitLabel(.done)
                    .onSubmit(save)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 10).stroke(Tape.faded))

                if !memories.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ON THIS DAY")
                            .font(Tape.font(10, weight: .bold))
                            .kerning(1.5)
                            .foregroundStyle(Tape.faded)
                        ForEach(memories, id: \.yearsAgo) { memory in
                            HStack(alignment: .top, spacing: 8) {
                                Text(memory.yearsAgo == 1 ? "1 YR AGO" : "\(memory.yearsAgo) YRS AGO")
                                    .font(Tape.font(10, weight: .semibold))
                                    .foregroundStyle(Tape.faded)
                                    .frame(width: 62, alignment: .leading)
                                if let emoji = memory.emoji { Text(emoji).font(.system(size: 12)) }
                                Text(memory.line.isEmpty ? "—" : memory.line)
                                    .font(Tape.font(12))
                                    .foregroundStyle(Tape.ink)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()

                if hasEntry {
                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Text("DELETE THIS DAY")
                            .font(Tape.font(12, weight: .semibold))
                            .foregroundStyle(Tape.alert)
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog("Delete this day?", isPresented: $confirmDelete) {
                        Button("Delete", role: .destructive) {
                            DataStore.delete(day: day)
                            dismiss()
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
            .padding(20)
            .background(Tape.paper)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .font(Tape.font(14, weight: .semibold))
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(Tape.font(14))
                }
            }
            .toolbarBackground(Tape.paper, for: .navigationBar)
            .tint(Tape.ink)
            .onAppear(perform: load)
        }
        .presentationDetents([.medium])
    }

    private func load() {
        let target = day
        let descriptor = FetchDescriptor<Entry>(predicate: #Predicate { $0.day == target })
        if let entry = try? DataStore.container.mainContext.fetch(descriptor).first {
            mood = entry.mood ?? .meh
            line = entry.line
            hasEntry = true
        }
        if pro.isPro { loadMemories() }
        focused = true
    }

    /// On This Day (Pro): same calendar date in earlier years.
    private func loadMemories() {
        let calendar = Calendar.current
        for years in 1...30 {
            guard let past = calendar.date(byAdding: .year, value: -years, to: day) else { break }
            let target = calendar.startOfDay(for: past)
            let descriptor = FetchDescriptor<Entry>(predicate: #Predicate { $0.day == target })
            if let entry = try? DataStore.container.mainContext.fetch(descriptor).first {
                memories.append((years, entry.mood?.emoji, entry.line))
            }
        }
    }

    private func save() {
        DataStore.upsert(day: day, mood: mood, line: line)
        dismiss()
    }
}
