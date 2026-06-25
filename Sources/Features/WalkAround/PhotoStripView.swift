import SwiftUI
import PhotosUI

/// Horizontal row of photo thumbnails plus an "add" tile. Handles camera +
/// library, enforces the Free photo cap, and routes over-cap taps to the paywall.
struct PhotoStripView: View {
    let photos: [InspectionPhoto]
    let cap: Int?              // nil = unlimited (Pro)
    var emptyHint: String = "Add a photo"
    let onAdd: (UIImage) -> Void
    let onDelete: (InspectionPhoto) -> Void
    var onUpgrade: () -> Void = {}

    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var pickerItem: PhotosPickerItem?

    private var atCap: Bool {
        if let cap { return photos.count >= cap }
        return false
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(photos) { photo in
                    thumbnail(photo)
                }
                addTile
            }
            .padding(.vertical, 2)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in onAdd(image) }
                .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showLibrary, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    onAdd(image)
                }
                pickerItem = nil
            }
        }
    }

    private func thumbnail(_ photo: InspectionPhoto) -> some View {
        let image = FileStorage.image(atRelative: photo.path)
        return ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.hairline
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
            .strokeBorder(Color.hairline, lineWidth: 0.5))
        .contextMenu {
            Button(role: .destructive) { onDelete(photo) } label: {
                Label("Remove photo", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private var addTile: some View {
        if atCap {
            Button(action: onUpgrade) {
                addTileLabel(icon: "lock.fill", text: "Pro")
            }
            .buttonStyle(.plain)
        } else {
            Menu {
                Button { showCamera = true } label: { Label("Take photo", systemImage: "camera") }
                Button { showLibrary = true } label: { Label("Choose from library", systemImage: "photo.on.rectangle") }
            } label: {
                addTileLabel(icon: "plus", text: "Add")
            }
        }
    }

    private func addTileLabel(icon: String, text: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 16, weight: .semibold))
            Text(text).font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(Color.clayDeep)
        .frame(width: 72, height: 72)
        .background(Color.peach.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
            .strokeBorder(Color.clay.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
    }
}
