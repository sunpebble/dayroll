import XCTest

/// Chinese screenshots for Dayroll. Uses `-seedDemo` entries, `-pro` and `-showStats`.
final class ScreenshotTests: XCTestCase {

    private func save(_ shot: XCUIScreenshot, _ name: String) {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? shot.pngRepresentation.write(to: dir.appendingPathComponent(name))
        let a = XCTAttachment(screenshot: shot); a.name = name; a.lifetime = .keepAlways; add(a)
    }

    @MainActor
    func testCaptureScreenshots() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_Hans", "-seedDemo", "-pro"]
        app.launch()
        sleep(5)
        save(XCUIScreen.main.screenshot(), "dayroll-zh-1-timeline.png")

        app.buttons["log"].tap(); sleep(2)
        // Fresh simulators show the swipe-typing keyboard intro over the compose sheet.
        for label in ["Continue", "继续"] where app.buttons[label].exists {
            app.buttons[label].tap(); sleep(1)
        }
        save(XCUIScreen.main.screenshot(), "dayroll-zh-2-compose.png")
        app.terminate()

        // Store already seeded by the first launch — don't re-seed (it would duplicate rows).
        let app2 = XCUIApplication()
        app2.launchArguments += ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_Hans", "-pro", "-showStats"]
        app2.launch()
        sleep(5)
        save(XCUIScreen.main.screenshot(), "dayroll-zh-3-stats.png")
    }
}
