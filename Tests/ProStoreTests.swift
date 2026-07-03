import XCTest
@testable import Dayroll

@MainActor
final class ProStoreTests: XCTestCase {
    override func setUp() {
        UserDefaults.standard.removeObject(forKey: ProStore.proCacheKey)
    }

    // product 未加载时点购买不能再静默失败——必须暴露原因,否则用户只看到「点了没反应」
    func testPurchaseWithoutProductSurfacesError() async {
        let store = ProStore()
        XCTAssertNil(store.product)

        await store.purchase()

        XCTAssertFalse(store.isPro)
        XCTAssertNotNil(store.purchaseError, "purchase with no product must surface an error, not fail silently")
    }
}
