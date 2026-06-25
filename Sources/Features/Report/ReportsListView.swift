import SwiftUI
import SwiftData

/// "Reports" tab — signed inspections only, ready to re-share.
struct ReportsListView: View {
    @Query(filter: #Predicate<Inspection> { $0.statusRaw == "signed" },
           sort: \Inspection.signedAt, order: .reverse)
    private var signed: [Inspection]

    @State private var openInspection: Inspection?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                BriefingHeader(
                    meta: "SIGNED & SAVED",
                    title: "Reports",
                    line: signed.isEmpty
                        ? "Signed inspections appear here, ready to re-send any time."
                        : "\(signed.count) signed record\(signed.count == 1 ? "" : "s"). Tap one to re-share its PDF.")
                    .padding(.top, 20)

                if signed.isEmpty {
                    ACMECard {
                        VStack(alignment: .leading, spacing: 8) {
                            IconTile(systemName: "doc.text.fill", size: 40)
                            Text("No reports yet")
                                .font(.acmeSection)
                                .foregroundStyle(Color.inkPrimary)
                            Text("Finish a walk-around and capture a signature to create your first report.")
                                .font(.acmeBody)
                                .foregroundStyle(Color.inkSecondary)
                        }
                    }
                } else {
                    ACMECard(padding: 8) {
                        VStack(spacing: 0) {
                            ForEach(Array(signed.enumerated()), id: \.element.id) { idx, inspection in
                                Button { openInspection = inspection } label: {
                                    InspectionRow(inspection: inspection)
                                        .padding(.horizontal, 8).padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                                if idx < signed.count - 1 {
                                    Divider().overlay(Color.hairline)
                                }
                            }
                        }
                    }
                }

                Spacer(minLength: 90)
            }
            .padding(.horizontal, 20)
        }
        .paperBackground()
        .fullScreenCover(item: $openInspection) { InspectionFlowView(start: .open($0)) }
    }
}
