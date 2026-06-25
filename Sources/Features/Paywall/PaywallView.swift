import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var store: StoreManager
    @Environment(\.dismiss) private var dismiss

    private let features: [(String, String)] = [
        ("rectangle.slash", "No watermark on your PDFs"),
        ("photo.badge.plus", "Your logo on every report"),
        ("photo.stack", "Unlimited photos per mark"),
        ("icloud", "iCloud backup (coming soon)"),
        ("square.and.arrow.up", "CSV & report history export")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("DENTPROOF PRO").acmeMetaRow()
                        Text("Make it yours")
                            .font(.acmeTitle)
                            .foregroundStyle(Color.inkPrimary)
                        Text("Drop the watermark, add your brand, and shoot as many photos as a job needs.")
                            .font(.acmeBody)
                            .foregroundStyle(Color.inkSecondary)
                    }
                    .padding(.top, 8)

                    ACMECard {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(features, id: \.1) { icon, text in
                                HStack(spacing: 12) {
                                    IconTile(systemName: icon, size: 30)
                                    Text(text).font(.acmeBodyMed).foregroundStyle(Color.inkPrimary)
                                    Spacer()
                                }
                            }
                        }
                    }

                    if store.isPro {
                        ACMECard {
                            HStack(spacing: 10) {
                                IconTile(systemName: "checkmark.seal.fill", size: 32)
                                Text("You're on Pro. Thank you!")
                                    .font(.acmeBodyMed).foregroundStyle(Color.inkPrimary)
                            }
                        }
                    } else {
                        VStack(spacing: 10) {
                            if let yearly = store.yearly {
                                planButton(yearly, highlight: true, caption: "Best value")
                            }
                            if let monthly = store.monthly {
                                planButton(monthly, highlight: false, caption: nil)
                            }
                            if store.products.isEmpty {
                                Text(store.isLoading ? "Loading options…" : "Subscription options will appear here once configured in App Store Connect.")
                                    .font(.acmeMeta)
                                    .foregroundStyle(Color.inkSecondary)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                            }
                            Button("Restore purchases") { Task { await store.restore() } }
                                .font(.acmeMeta)
                                .foregroundStyle(Color.clayDeep)
                                .padding(.top, 2)
                        }
                    }

                    Text("Subscriptions renew automatically until cancelled. Manage or cancel anytime in your App Store account settings.")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.inkSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    Spacer(minLength: 10)
                }
                .padding(20)
            }
            .paperBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }.font(.acmeBodyMed)
                }
            }
            .onChange(of: store.isPro) { _, isPro in
                if isPro { Haptics.success() }
            }
        }
    }

    private func planButton(_ product: Product, highlight: Bool, caption: String?) -> some View {
        Button {
            Task { await store.purchase(product) }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName).font(.acmeBodyMed)
                    if let caption {
                        Text(caption).font(.acmeMeta).opacity(0.85)
                    }
                }
                Spacer()
                Text(product.displayPrice).font(.acmeBodyMed)
            }
            .foregroundStyle(highlight ? Color.onClay : Color.inkPrimary)
            .padding(.vertical, 14).padding(.horizontal, 18)
            .background(highlight ? Color.clayDeep : Color.cream)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(highlight ? Color.clear : Color.hairline, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .disabled(store.isLoading)
    }
}
