import UIKit

enum ImageCompression {
    static let maxDimension: CGFloat = 1600
    static let jpegQuality: CGFloat = 0.72

    /// Downscales so the longest side is at most `maxDimension`, preserving aspect.
    static func resize(_ image: UIImage, maxDimension: CGFloat = maxDimension) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxDimension else { return image }
        let scale = maxDimension / longest
        let newSize = CGSize(width: image.size.width * scale,
                             height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    static func jpegData(from image: UIImage) -> Data? {
        resize(image).jpegData(compressionQuality: jpegQuality)
    }
}
