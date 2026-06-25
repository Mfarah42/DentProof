import SwiftUI
import MessageUI

/// Prefilled Messages composer with the PDF attached. Falls back gracefully:
/// callers should check `MessageComposer.canSend` and use the share sheet
/// otherwise (e.g. on Simulator or iPads without iMessage).
struct MessageComposer: UIViewControllerRepresentable {
    let recipients: [String]
    let body: String
    let attachmentURL: URL?
    var onFinish: () -> Void = {}

    static var canSend: Bool { MFMessageComposeViewController.canSendText() }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.messageComposeDelegate = context.coordinator
        vc.recipients = recipients
        vc.body = body
        if let url = attachmentURL,
           let data = try? Data(contentsOf: url),
           MFMessageComposeViewController.canSendAttachments() {
            vc.addAttachmentData(data, typeIdentifier: "com.adobe.pdf",
                                 filename: url.lastPathComponent)
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let onFinish: () -> Void
        init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
        func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                          didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true) { self.onFinish() }
        }
    }
}
