import StoreKit
import SwiftUI

/// StoreKit 2 wrapper for the single "DentProof Pro" subscription group.
/// Source of truth for entitlement is `Transaction.currentEntitlements`; we
/// mirror the result into `isPro` for the UI and into BusinessProfile for the
/// PDF watermark gate.
@MainActor
final class StoreManager: ObservableObject {

    enum ProductID {
        static let monthly = "com.dentproof.pro.monthly"
        static let yearly  = "com.dentproof.pro.yearly"
        static let all: [String] = [monthly, yearly]
    }

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPro: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published var lastError: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        // Listen for transactions that arrive outside an explicit purchase
        // (renewals, restores on other devices, Ask-to-Buy approvals…).
        updatesTask = Task.detached { [weak self] in
            for await update in Transaction.updates {
                guard let self else { continue }
                if let transaction = try? self.checkVerified(update) {
                    await transaction.finish()
                    await self.refreshEntitlements()
                }
            }
        }
    }

    deinit { updatesTask?.cancel() }

    var monthly: Product? { products.first { $0.id == ProductID.monthly } }
    var yearly: Product?  { products.first { $0.id == ProductID.yearly } }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let loaded = try await Product.products(for: ProductID.all)
            products = loaded.sorted { $0.price < $1.price }
        } catch {
            lastError = "Couldn't load subscription options."
        }
        await refreshEntitlements()
    }

    func purchase(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
            case .userCancelled:
                break
            case .pending:
                lastError = "Purchase is pending approval."
            @unknown default:
                break
            }
        } catch {
            lastError = "Purchase failed. Please try again."
        }
    }

    func restore() async {
        isLoading = true
        defer { isLoading = false }
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    /// Recomputes `isPro` from current entitlements.
    func refreshEntitlements() async {
        var active = false
        for await entitlement in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(entitlement),
               ProductID.all.contains(transaction.productID),
               transaction.revocationDate == nil {
                active = true
            }
        }
        isPro = active
    }

    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    enum StoreError: Error { case failedVerification }
}
