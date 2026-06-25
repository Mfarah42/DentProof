import SwiftUI
import SwiftData

struct MarkerDetailSheet: View {
    @Bindable var mark: DamageMark
    let photoCap: Int?
    let isPro: Bool
    var onUpgrade: () -> Void
    var onDelete: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private let typeColumns = [GridItem(.adaptive(minimum: 96), spacing: 8)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Type").acmeMetaRow()
                        LazyVGrid(columns: typeColumns, spacing: 8) {
                            ForEach(DamageType.allCases) { type in
                                typeChip(type)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location").acmeMetaRow()
                        DPTextField(title: "e.g. L front door", text: $mark.locationLabel)
                        quickLocations
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note (optional)").acmeMetaRow()
                        DPTextField(title: "Anything worth recording",
                                    text: Binding($mark.note, default: ""),
                                    autocap: .sentences)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Photos of this mark").acmeMetaRow()
                        PhotoStripView(
                            photos: mark.photos.sorted { $0.createdAt < $1.createdAt },
                            cap: photoCap,
                            onAdd: { addPhoto($0) },
                            onDelete: { deletePhoto($0) },
                            onUpgrade: onUpgrade)
                        if let photoCap, !isPro {
                            Text("Free plan: up to \(photoCap) photos per mark. Upgrade for unlimited.")
                                .font(.acmeMeta)
                                .foregroundStyle(Color.inkSecondary)
                        }
                    }

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete this mark", systemImage: "trash")
                            .font(.acmeBodyMed)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .overlay(Capsule().strokeBorder(Color.clay.opacity(0.5), lineWidth: 0.5))
                    }
                    .tint(.clayDeep)

                    Spacer(minLength: 10)
                }
                .padding(20)
            }
            .paperBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { try? context.save(); dismiss() }
                        .font(.acmeBodyMed)
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.clay)
                Text("\(mark.index)").font(.system(size: 17, weight: .bold)).foregroundStyle(Color.onClay)
            }.frame(width: 36, height: 36)
            Text("Mark \(mark.index)")
                .font(.acmeSection)
                .foregroundStyle(Color.inkPrimary)
        }
    }

    private func typeChip(_ type: DamageType) -> some View {
        let selected = mark.type == type
        return Button {
            Haptics.light()
            mark.type = type
        } label: {
            HStack(spacing: 6) {
                Image(systemName: type.symbol).font(.system(size: 12, weight: .semibold))
                Text(type.displayName).font(.acmeLabel)
            }
            .foregroundStyle(selected ? Color.onClay : Color.inkPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(selected ? Color.clayDeep : Color.cream)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(Color.hairline, lineWidth: selected ? 0 : 0.5))
        }
        .buttonStyle(.plain)
    }

    private let commonLocations = ["L front", "R front", "L rear", "R rear", "Hood", "Roof", "Trunk", "Bumper"]

    private var quickLocations: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(commonLocations, id: \.self) { loc in
                    Button { mark.locationLabel = loc } label: {
                        Text(loc)
                            .font(.acmeMeta)
                            .foregroundStyle(Color.clayDeep)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Capsule().fill(Color.peach.opacity(0.7)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func addPhoto(_ image: UIImage) {
        guard let relPath = FileStorage.savePhoto(image) else { return }
        let photo = InspectionPhoto()
        photo.path = relPath
        photo.mark = mark
        context.insert(photo)
        mark.photos.append(photo)
        try? context.save()
    }

    private func deletePhoto(_ photo: InspectionPhoto) {
        FileStorage.delete(relativePath: photo.path)
        context.delete(photo)
        try? context.save()
    }
}
