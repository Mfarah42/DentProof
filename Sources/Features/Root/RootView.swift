import SwiftUI
import SwiftData

enum AppTab: Int, CaseIterable {
    case today, jobs, reports, alerts

    var title: String {
        switch self {
        case .today:   return "Today"
        case .jobs:    return "Jobs"
        case .reports: return "Reports"
        case .alerts:  return "Alerts"
        }
    }
    var icon: String {
        switch self {
        case .today:   return "sun.max"
        case .jobs:    return "car"
        case .reports: return "doc.text"
        case .alerts:  return "bell"
        }
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var store: StoreManager
    @Query private var profiles: [BusinessProfile]
    @State private var selectedTab: AppTab = .today

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.paper.ignoresSafeArea()

            Group {
                switch selectedTab {
                case .today:   TodayView()
                case .jobs:    JobsListView()
                case .reports: ReportsListView()
                case .alerts:  AlertsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            TabPill(selected: $selectedTab)
                .padding(.horizontal, 28)
                .padding(.bottom, 6)
        }
        .onAppear(perform: ensureProfile)
        .onChange(of: store.isPro) { _, isPro in
            // Mirror the live StoreKit entitlement into the cached flag the
            // deeper screens read for gating (photo caps, watermark, branding).
            if let profile = profiles.first, profile.isPro != isPro {
                profile.isPro = isPro
                try? context.save()
            }
        }
    }

    private func ensureProfile() {
        if profiles.isEmpty {
            let p = BusinessProfile()
            p.isPro = store.isPro
            context.insert(p)
            try? context.save()
        }
    }
}

/// Floating cream capsule tab bar (not a system tab bar).
struct TabPill: View {
    @Binding var selected: AppTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    Haptics.light()
                    selected = tab
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.icon)
                            .symbolVariant(selected == tab ? .fill : .none)
                            .font(.system(size: 17, weight: .medium))
                        Text(tab.title)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(selected == tab ? Color.clayDeep : Color.inkSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .background(
            Capsule()
                .fill(Color.cream)
                .shadow(color: Color.black.opacity(0.10), radius: 12, y: 4)
                .overlay(Capsule().strokeBorder(Color.hairline, lineWidth: 0.5))
        )
    }
}
