import UIKit

/// All binary assets (photos, signatures, logo) live as files on disk inside
/// the app's Documents directory. The SwiftData store only ever holds the
/// *relative* path, keeping the database small and fast.
enum FileStorage {

    static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private static let photosDir = "photos"
    private static let signaturesDir = "signatures"
    private static let brandingDir = "branding"

    private static func ensureDir(_ name: String) -> URL {
        let url = documentsURL.appendingPathComponent(name, isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    // MARK: - Resolve

    /// Absolute URL for a stored relative path.
    static func url(forRelative relativePath: String) -> URL {
        documentsURL.appendingPathComponent(relativePath)
    }

    static func image(atRelative relativePath: String?) -> UIImage? {
        guard let relativePath, !relativePath.isEmpty else { return nil }
        let url = url(forRelative: relativePath)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    // MARK: - Save

    /// Compresses to ~1600px JPEG and returns the relative path.
    @discardableResult
    static func savePhoto(_ image: UIImage) -> String? {
        let dir = ensureDir(photosDir)
        let name = "\(UUID().uuidString).jpg"
        let url = dir.appendingPathComponent(name)
        guard let data = ImageCompression.jpegData(from: image) else { return nil }
        do {
            try data.write(to: url, options: .atomic)
            return "\(photosDir)/\(name)"
        } catch {
            return nil
        }
    }

    /// Saves a signature PNG (preserves transparency).
    @discardableResult
    static func saveSignature(_ image: UIImage) -> String? {
        let dir = ensureDir(signaturesDir)
        let name = "\(UUID().uuidString).png"
        let url = dir.appendingPathComponent(name)
        guard let data = image.pngData() else { return nil }
        do {
            try data.write(to: url, options: .atomic)
            return "\(signaturesDir)/\(name)"
        } catch {
            return nil
        }
    }

    /// Saves the business logo (PNG) and returns the relative path.
    @discardableResult
    static func saveLogo(_ image: UIImage) -> String? {
        let dir = ensureDir(brandingDir)
        let name = "logo-\(UUID().uuidString).png"
        let url = dir.appendingPathComponent(name)
        let resized = ImageCompression.resize(image, maxDimension: 600)
        guard let data = resized.pngData() else { return nil }
        do {
            try data.write(to: url, options: .atomic)
            return "\(brandingDir)/\(name)"
        } catch {
            return nil
        }
    }

    // MARK: - Delete

    static func delete(relativePath: String?) {
        guard let relativePath, !relativePath.isEmpty else { return }
        try? FileManager.default.removeItem(at: url(forRelative: relativePath))
    }
}
