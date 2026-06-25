import SwiftUI
import PencilKit

/// PencilKit canvas for the customer's signature. `clearToken` lets the parent
/// force a clear; `isEmpty` reports whether anything has been drawn.
struct SignatureCanvas: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    var onChange: (_ isEmpty: Bool) -> Void

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput   // finger or Apple Pencil
        canvasView.tool = PKInkingTool(.pen, color: .label, width: 3)
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.delegate = context.coordinator
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        let parent: SignatureCanvas
        init(_ parent: SignatureCanvas) { self.parent = parent }
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.onChange(canvasView.drawing.bounds.isEmpty)
        }
    }
}

extension PKCanvasView {
    /// Rasterizes the drawing to a PNG-friendly UIImage with a transparent
    /// background, trimmed to the drawing bounds with a little padding.
    func signatureImage(scale: CGFloat = 3) -> UIImage? {
        let drawing = self.drawing
        guard !drawing.bounds.isEmpty else { return nil }
        let pad: CGFloat = 12
        let rect = drawing.bounds.insetBy(dx: -pad, dy: -pad)
        return drawing.image(from: rect, scale: scale)
    }
}
