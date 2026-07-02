import Foundation
import StoreKit

@Observable
final class ProStore {
    static let productID = "com.sunpebble.dayroll.lifetime"

    var isPro = false
    var product: Product?

    var displayPrice: String { product?.displayPrice ?? "$1.99" }

    @MainActor
    func load() async {
        #if DEBUG
        if CommandLine.arguments.contains("-pro") {
            isPro = true
            return
        }
        #endif
        product = try? await Product.products(for: [Self.productID]).first
        await refresh()
    }

    @MainActor
    func refresh() async {
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement,
               transaction.productID == Self.productID {
                isPro = true
            }
        }
    }

    @MainActor
    func purchase() async {
        guard let product else { return }
        guard let result = try? await product.purchase() else { return }
        if case .success(.verified(let transaction)) = result {
            isPro = true
            await transaction.finish()
        }
    }

    @MainActor
    func restore() async {
        try? await AppStore.sync()
        await refresh()
    }

    @MainActor
    func listenForTransactions() async {
        for await update in Transaction.updates {
            if case .verified(let transaction) = update,
               transaction.productID == Self.productID {
                isPro = true
                await transaction.finish()
            }
        }
    }
}
