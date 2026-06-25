import SwiftUI
import SwiftData

struct JobsListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Inspection.createdAt, order: .reverse) private var inspections: [Inspection]

    @State private var openInspection: Inspection?
    @State private var showNewFlow = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                BriefingHeader(
                    meta: "ALL WALK-AROUNDS",
                    title: "Jobs",
                    line: line)
                    .padding(.top, 20)

                ClayButton(title: "New inspection", icon: "plus") { showNewFlow = true }

                if inspections.isEmpty {
                    ACMECard {
                        VStack(alignment: .leading, spacing: 8) {
                            IconTile(systemName: "car.fill", size: 40)
                            Text("Nothing here yet")
                                .font(.acmeSection)
                                .foregroundStyle(Color.inkPrimary)
                            Text("Every inspection you create shows up here, newest first.")
                                .font(.acmeBody)
                                .foregroundStyle(Color.inkSecondary)
                        }
                    }
                } else {
                    listCard
                }

                Spacer(minLength: 90)
            }
            .padding(.horizontal, 20)
        }
        .paperBackground()
        .fullScreenCover(item: $openInspection) { InspectionFlowView(start: .open($0)) }
        .fullScreenCover(isPresented: $showNewFlow) { InspectionFlowView(start: .new) }
    }

    private var line: String {
        let drafts = inspections.filter { $0.status == .draft }.count
        let signed = inspections.filter { $0.status == .signed }.count
        if inspections.isEmpty { return "Your inspections will collect here." }
        return "\(signed) signed · \(drafts) draft\(drafts == 1 ? "" : "s")."
    }

    private var listCard: some View {
        ACMECard(padding: 8) {
            VStack(spacing: 0) {
                ForEach(Array(inspections.enumerated()), id: \.element.id) { idx, inspection in
                    Button { openInspection = inspection } label: {
                        InspectionRow(inspection: inspection)
                            .padding(.horizontal, 8).padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            delete(inspection)
                        } label: { Label("Delete inspection", systemImage: "trash") }
                    }
                    if idx < inspections.count - 1 {
                        Divider().overlay(Color.hairline)
                    }
                }
            }
        }
    }

    private func delete(_ inspection: Inspection) {
        // Clean up files referenced by this inspection before deleting the row.
        FileStorage.delete(relativePath: inspection.signaturePath)
        for photo in inspection.generalPhotos { FileStorage.delete(relativePath: photo.path) }
        for mark in inspection.marks {
            for photo in mark.photos { FileStorage.delete(relativePath: photo.path) }
        }
        context.delete(inspection)
        try? context.save()
    }
}
