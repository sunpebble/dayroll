import XCTest
import SwiftUI
import UIKit
@testable import Dayroll

final class TapeColorTests: XCTestCase {
    /// 把 SwiftUI Color 在指定外观下解析为 RGB 分量。
    private func components(
        _ color: Color,
        style: UIUserInterfaceStyle
    ) -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color)
            .resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
            .getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }

    func testPaperInvertsInDarkMode() {
        let light = components(Tape.paper, style: .light)
        XCTAssertEqual(light.r, 1.0, accuracy: 0.01)
        XCTAssertEqual(light.g, 0.965, accuracy: 0.01)
        XCTAssertEqual(light.b, 0.91, accuracy: 0.01)

        let dark = components(Tape.paper, style: .dark)
        XCTAssertEqual(dark.r, 0.129, accuracy: 0.01)
        XCTAssertEqual(dark.g, 0.118, accuracy: 0.01)
        XCTAssertEqual(dark.b, 0.102, accuracy: 0.01)
    }

    func testInkInvertsInDarkMode() {
        let light = components(Tape.ink, style: .light)
        XCTAssertEqual(light.r, 0.137, accuracy: 0.01)
        XCTAssertEqual(light.g, 0.153, accuracy: 0.01)
        XCTAssertEqual(light.b, 0.20, accuracy: 0.01)

        let dark = components(Tape.ink, style: .dark)
        XCTAssertEqual(dark.r, 0.922, accuracy: 0.01)
        XCTAssertEqual(dark.g, 0.890, accuracy: 0.01)
        XCTAssertEqual(dark.b, 0.816, accuracy: 0.01)
    }

    func testAlertBrightensInDarkMode() {
        let dark = components(Tape.alert, style: .dark)
        XCTAssertEqual(dark.r, 0.898, accuracy: 0.01)
        XCTAssertEqual(dark.g, 0.357, accuracy: 0.01)
        XCTAssertEqual(dark.b, 0.290, accuracy: 0.01)
    }

    func testFadedTracksInkAtHalfOpacity() {
        XCTAssertEqual(components(Tape.faded, style: .light).a, 0.55, accuracy: 0.01)
        XCTAssertEqual(components(Tape.faded, style: .dark).a, 0.55, accuracy: 0.01)
    }
}
