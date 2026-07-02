import AppIntents

struct LogMoodIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Mood"
    static var description = IntentDescription("Log today's mood on your tape.")

    @Parameter(title: "Mood") var mood: Mood

    init() {}
    init(mood: Mood) { self.mood = mood }

    @MainActor
    func perform() async throws -> some IntentResult {
        DataStore.upsert(mood: mood)
        return .result()
    }
}
