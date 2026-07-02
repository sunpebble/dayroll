import Foundation
import StoreKit

@Observable
final class ProStore {
    static let productID = "com.sunpebble.dayroll.lifetime"

    var isPro = false
    var product: Product?
    var purchaseError: String?

    var displayPrice: String { product?.displayPrice ?? "$1.99" }

    @MainActor
    func load() async {
        #if DEBUG
        if CommandLine.arguments.contains("-pro") {
            isPro = true
            return
        }
        #endif
        do {
            product = try await Product.products(for: [Self.productID]).first
            if product == nil {
                purchaseError = "Product not available. Check App Store Connect setup."
            }
        } catch {
            purchaseError = "Couldn't load product: \(error.localizedDescription)"
        }
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
        purchaseError = nil
        guard let product else {
            purchaseError = "Product not available. Check App Store Connect setup."
            return
        }
        do {
            switch try await product.purchase() {
            case .success(.verified(let transaction)):
                isPro = true
                await transaction.finish()
            case .success(.unverified(_, let error)):
                purchaseError = "Purchase couldn't be verified: \(error.localizedDescription)"
            case .pending:
                purchaseError = "Purchase is pending approval."
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = "Purchase failed: \(error.localizedDescription)"
        }
    }

    @MainActor
    func restore() async {
        purchaseError = nil
        do {
            try await AppStore.sync()
        } catch {
            purchaseError = "Restore failed: \(error.localizedDescription)"
        }
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
