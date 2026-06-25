import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Inspection.createdAt, order: .reverse) private var inspections: [Inspection]

    @State private var showNewFlow = false
    @State private var openInspection: Inspection?
    @State private var showSettings = false

    private var recent: [Inspection] { Array(inspections.prefix(8)) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                BriefingHeader(
                    meta: DP.metaDate(),
                    title: "Today",
                    line: briefingLine)

                ClayButton(title: "New inspection", icon: "plus") {
                    showNewFlow = true
                }

                if recent.isEmpty {
                    emptyState
                } else {
                    recentCard
                }

                Spacer(minLength: 90)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .paperBackground()
        .fullScreenCover(isPresented: $showNewFlow) {
            InspectionFlowView(start: .new)
        }
        .fullScreenCover(item: $openInspection) { inspection in
            InspectionFlowView(start: .open(inspection))
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - Pieces

    private var header: some View {
        HStack {
            Text("DentProof")
                .font(.system(size: 17, weight: .semibold, design: .serif))
                .foregroundStyle(Color.inkPrimary)
            Spacer()
            Button { showSettings = true } label: {
                IconTile(systemName: "gearshape.fill", size: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }

    private var briefingLine: String {
        let signedToday = inspections.filter {
            $0.status == .signed && Calendar.current.isDateInToday($0.signedAt ?? $0.createdAt)
        }.count
        let drafts = inspections.filter { $0.status == .draft }.count

        if inspections.isEmpty {
            return "Document a car's condition before you start. Tap below to begin."
        }
        if signedToday > 0 && drafts == 0 {
            let n = signedToday == 1 ? "One car" : "\(signedToday) cars"
            return "\(n) done and signed. Nothing's waiting on you."
        }
        if drafts > 0 {
            return drafts == 1
                ? "One draft is still open. Finish it or start something new."
                : "\(drafts) drafts are still open. Finish them or start fresh."
        }
        return "Tap below to document your next walk-around."
    }

    private var recentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent").acmeMetaRow()
            ACMECard(padding: 8) {
                VStack(spacing: 0) {
                    ForEach(Array(recent.enumerated()), id: \.element.id) { idx, inspection in
                        Button { openInspection = inspection } label: {
                            InspectionRow(inspection: inspection)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        if idx < recent.count - 1 {
                            Divider().overlay(Color.hairline)
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        ACMECard {
            VStack(alignment: .leading, spacing: 10) {
                IconTile(systemName: "car.fill", size: 40)
                Text("No inspections yet")
                    .font(.acmeSection)
                    .foregroundStyle(Color.inkPrimary)
                Text("Start your first walk-around. It takes under a minute and you'll have a signed record.")
                    .font(.acmeBody)
                    .foregroundStyle(Color.inkSecondary)
            }
        }
    }
}
