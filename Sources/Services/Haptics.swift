import UIKit

enum Haptics {
    /// The signature "marker dropped on the car" feedback — soft and deliberate.
    static func markerDrop() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred(intensity: 0.9)
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
