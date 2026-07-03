import SwiftUI

/// Receipt-paper design tokens. Paper/ink are the shared Sunpebble
/// cream #FFF6E8 / ink #232733 (same values as Simmer & Sleeptab);
/// the receipt personality lives in the monospaced type and Perforation.
enum Tape {
    static let paper = Color(red: 1.0, green: 0.965, blue: 0.91)
    static let ink = Color(red: 0.137, green: 0.153, blue: 0.20)
    static let faded = ink.opacity(0.55)
    static let alert = Color(red: 0.72, green: 0.13, blue: 0.09)

    static func font(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

/// Soft press feedback: the system press highlight glares against receipt paper.
struct TapePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

struct Perforation: View {
    var body: some View {
        Line()
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            .foregroundStyle(Tape.faded)
            .frame(height: 1)
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
            return path
        }
    }
}
