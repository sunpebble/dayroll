import AppIntents

enum Mood: String, CaseIterable, Codable, Sendable {
    case great, good, meh, bad, awful

    var emoji: String {
        switch self {
        case .great: "😄"
        case .good: "🙂"
        case .meh: "😐"
        case .bad: "😞"
        case .awful: "😣"
        }
    }

    var score: Int {
        switch self {
        case .great: 5
        case .good: 4
        case .meh: 3
        case .bad: 2
        case .awful: 1
        }
    }
}

extension Mood: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Mood"
    static var caseDisplayRepresentations: [Mood: DisplayRepresentation] = [
        .great: "😄 Great",
        .good: "🙂 Good",
        .meh: "😐 Meh",
        .bad: "😞 Bad",
        .awful: "😣 Awful",
    ]
}
