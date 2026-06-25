import SwiftUI
import SwiftData

struct WalkAroundView: View {
    @Bindable var inspection: Inspection
    @Binding var path: NavigationPath

    @Environment(\.modelContext) private var context
    @Query private var profiles: [BusinessProfile]

    @State private var selectedMark: DamageMark?
    @State private var showPaywall = false

    private var isPro: Bool { profiles.first?.isPro ?? false }
    private var photoCapPerMark: Int? { isPro ? nil : 2 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                BriefingHeader(
                    meta: vehicleMeta,
                    title: "Pre-existing condition",
                    line: briefingLine)
                    .padding(.top, 8)

                diagramCard

                generalPhotosSection

                if !inspection.marksSorted.isEmpty {
                    markListSection
                }

                ClayButton(title: "Continue to signature", icon: "signature") {
                    try? context.save()
                    path.append(FlowRoute.signature(inspection))
                }

                Spacer(minLength: 30)
            }
            .padding(.horizontal, 20)
        }
        .paperBackground()
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedMark) { mark in
            MarkerDetailSheet(
                mark: mark,
                photoCap: photoCapPerMark,
                isPro: isPro,
                onUpgrade: { selectedMark = nil; showPaywall = true },
                onDelete: { deleteMark(mark) })
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    // MARK: - Diagram

    private var diagramCard: some View {
        ACMECard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tap the car to drop a marker").acmeMetaRow()
                // Lock the same aspect ratio the PDF uses so marker positions
                // (stored normalized) line up identically on screen and in print.
                Color.clear
                    .aspectRatio(kDiagramAspect, contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: 430)
                    .overlay {
                        GeometryReader { geo in
                            ZStack {
                                VehicleDiagramView(style: inspection.bodyStyle)
                                    .contentShape(Rectangle())
                                    .gesture(
                                        SpatialTapGesture(coordinateSpace: .local)
                                            .onEnded { value in
                                                addMark(
                                                    x: value.location.x / geo.size.width,
                                                    y: value.location.y / geo.size.height)
                                            }
                                    )

                                ForEach(inspection.marksSorted) { mark in
                                    DraggableMarker(
                                        mark: mark,
                                        diagramSize: geo.size,
                                        onTap: { selectedMark = mark },
                                        onCommit: { try? context.save() })
                                        .transition(.asymmetric(
                                            insertion: .scale(scale: 0.2).combined(with: .opacity),
                                            removal: .opacity))
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var generalPhotosSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Before photos").acmeMetaRow()
            Text("Optional wide shots of the whole car, not tied to a single mark.")
                .font(.acmeMeta)
                .foregroundStyle(Color.inkSecondary)
            PhotoStripView(
                photos: inspection.generalPhotos.sorted { $0.createdAt < $1.createdAt },
                cap: isPro ? nil : 4,
                onAdd: { addGeneralPhoto($0) },
                onDelete: { deleteGeneralPhoto($0) },
                onUpgrade: { showPaywall = true })
        }
    }

    private var markListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Marks").acmeMetaRow()
            ACMECard(padding: 8) {
                VStack(spacing: 0) {
                    let marks = inspection.marksSorted
                    ForEach(Array(marks.enumerated()), id: \.element.id) { idx, mark in
                        Button { selectedMark = mark } label: {
                            MarkSummaryRow(mark: mark)
                                .padding(.horizontal, 8).padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        if idx < marks.count - 1 { Divider().overlay(Color.hairline) }
                    }
                }
            }
        }
    }

    // MARK: - Copy

    private var vehicleMeta: String {
        let parts = [inspection.vehicleTitle, inspection.vehicleColor]
            .filter { !$0.isEmpty && $0 != "Vehicle" }
        return parts.isEmpty ? "WALK-AROUND" : parts.joined(separator: " · ").uppercased()
    }

    private var briefingLine: String {
        let n = inspection.marks.count
        switch n {
        case 0: return "No marks yet. Tap the car to log anything that's already there — or sign a clean record."
        case 1: return "1 mark found before you start. Tap the car to add more."
        default: return "\(n) marks found before you start. Tap the car to add more."
        }
    }

    // MARK: - Mutations

    private func addMark(x: Double, y: Double) {
        let mark = DamageMark()
        mark.index = (inspection.marks.map(\.index).max() ?? 0) + 1
        mark.x = min(max(x, 0.04), 0.96)
        mark.y = min(max(y, 0.03), 0.97)
        mark.inspection = inspection
        context.insert(mark)
        inspection.marks.append(mark)
        try? context.save()

        Haptics.markerDrop()
        withAnimation(.spring(response: 0.34, dampingFraction: 0.6)) {}
        selectedMark = mark
    }

    private func deleteMark(_ mark: DamageMark) {
        for photo in mark.photos { FileStorage.delete(relativePath: photo.path) }
        // Re-number remaining marks so labels stay 1…N.
        context.delete(mark)
        let remaining = inspection.marks.filter { $0.id != mark.id }.sorted { $0.index < $1.index }
        for (i, m) in remaining.enumerated() { m.index = i + 1 }
        try? context.save()
        selectedMark = nil
    }

    private func addGeneralPhoto(_ image: UIImage) {
        guard let relPath = FileStorage.savePhoto(image) else { return }
        let photo = InspectionPhoto()
        photo.path = relPath
        photo.inspection = inspection
        context.insert(photo)
        inspection.generalPhotos.append(photo)
        try? context.save()
    }

    private func deleteGeneralPhoto(_ photo: InspectionPhoto) {
        FileStorage.delete(relativePath: photo.path)
        context.delete(photo)
        try? context.save()
    }
}

// MARK: - Draggable marker

private struct DraggableMarker: View {
    @Bindable var mark: DamageMark
    let diagramSize: CGSize
    let onTap: () -> Void
    let onCommit: () -> Void

    @State private var dragTranslation: CGSize = .zero
    @State private var isDragging = false

    var body: some View {
        let base = CGPoint(x: diagramSize.width * mark.x,
                           y: diagramSize.height * mark.y)
        DiagramMarker(number: mark.index, isSelected: isDragging)
            .position(x: base.x + dragTranslation.width,
                      y: base.y + dragTranslation.height)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        dragTranslation = value.translation
                    }
                    .onEnded { value in
                        let moved = hypot(value.translation.width, value.translation.height)
                        if moved < 6 {
                            // Treat as a tap.
                            dragTranslation = .zero
                            isDragging = false
                            onTap()
                        } else {
                            let newX = (base.x + value.translation.width) / diagramSize.width
                            let newY = (base.y + value.translation.height) / diagramSize.height
                            mark.x = min(max(newX, 0.04), 0.96)
                            mark.y = min(max(newY, 0.03), 0.97)
                            dragTranslation = .zero
                            isDragging = false
                            Haptics.light()
                            onCommit()
                        }
                    }
            )
    }
}

// MARK: - Mark summary row

struct MarkSummaryRow: View {
    let mark: DamageMark
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.clay)
                Text("\(mark.index)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.onClay)
            }
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(mark.type.displayName)
                    .font(.acmeBodyMed)
                    .foregroundStyle(Color.inkPrimary)
                Text(mark.locationLabel.isEmpty ? "No location noted" : mark.locationLabel)
                    .font(.acmeMeta)
                    .foregroundStyle(Color.inkSecondary)
            }
            Spacer()
            if !mark.photos.isEmpty {
                HStack(spacing: 3) {
                    Image(systemName: "photo").font(.system(size: 11))
                    Text("\(mark.photos.count)").font(.acmeMeta)
                }
                .foregroundStyle(Color.inkSecondary)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.hairline)
        }
    }
}
