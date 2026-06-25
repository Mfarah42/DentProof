import SwiftUI
import SwiftData
import PencilKit

struct SignatureView: View {
    @Bindable var inspection: Inspection
    @Binding var path: NavigationPath

    @Environment(\.modelContext) private var context

    @State private var canvasView = PKCanvasView()
    @State private var isEmpty = true
    @State private var isSaving = false
    @State private var locationService = LocationService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                BriefingHeader(
                    meta: "ALMOST DONE",
                    title: "Sign to confirm",
                    line: agreementLine)
                    .padding(.top, 8)

                ACMECard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("I confirm the marks above show the vehicle's condition before service.")
                            .font(.acmeBody)
                            .foregroundStyle(Color.inkPrimary)

                        ZStack(alignment: .bottomLeading) {
                            SignatureCanvas(canvasView: $canvasView, onChange: { isEmpty = $0 })
                                .frame(height: 200)
                                .background(Color.paper)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color.hairline, lineWidth: 0.5))

                            if isEmpty {
                                Text("Sign here")
                                    .font(.acmeMeta)
                                    .foregroundStyle(Color.inkSecondary)
                                    .padding(12)
                                    .allowsHitTesting(false)
                            }
                        }

                        HStack {
                            Text(customerLabel)
                                .font(.acmeMeta)
                                .foregroundStyle(Color.inkSecondary)
                            Spacer()
                            Button("Clear") {
                                canvasView.drawing = PKDrawing()
                                isEmpty = true
                            }
                            .font(.acmeMeta)
                            .foregroundStyle(Color.clayDeep)
                        }
                    }
                }

                Text("Location is stamped only if you allow it, and it never leaves this phone.")
                    .font(.acmeMeta)
                    .foregroundStyle(Color.inkSecondary)

                ClayButton(title: isSaving ? "Saving…" : "Sign & save",
                           icon: "checkmark",
                           isEnabled: !isEmpty && !isSaving) {
                    sign()
                }

                Spacer(minLength: 30)
            }
            .padding(.horizontal, 20)
        }
        .paperBackground()
        .navigationBarTitleDisplayMode(.inline)
    }

    private var agreementLine: String {
        let n = inspection.marks.count
        if n == 0 {
            return "A clean record. Capture the customer's signature confirming no pre-existing damage."
        }
        return "Capture the customer's signature confirming the \(n) mark\(n == 1 ? "" : "s") you logged."
    }

    private var customerLabel: String {
        inspection.customerName.isEmpty ? "Customer signature" : "\(inspection.customerName) — signature"
    }

    private func sign() {
        guard let image = canvasView.signatureImage(),
              let relPath = FileStorage.saveSignature(image) else { return }
        isSaving = true

        inspection.signaturePath = relPath
        inspection.signedAt = Date()
        inspection.status = .signed

        // One-shot, optional GPS. We proceed immediately regardless of result.
        locationService.requestOneShot { coord in
            if let coord {
                inspection.latitude = coord.latitude
                inspection.longitude = coord.longitude
            }
            try? context.save()
            Haptics.success()
            isSaving = false
            path.append(FlowRoute.report(inspection))
        }

        // Safety: if the location closure is slow, the timeout inside
        // LocationService (6s) guarantees it still fires. We save the signed
        // state right away so nothing is lost even if the view goes away.
        try? context.save()
    }
}
