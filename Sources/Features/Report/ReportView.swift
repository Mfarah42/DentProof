import SwiftUI
import SwiftData

struct ReportView: View {
    @Bindable var inspection: Inspection
    let onClose: () -> Void

    @Environment(\.modelContext) private var context
    @Query private var profiles: [BusinessProfile]

    @State private var pdfURL: URL?
    @State private var isGenerating = false
    @State private var showShare = false
    @State private var showMessage = false
    @State private var nudgeScheduled = false

    private var profile: BusinessProfile? { profiles.first }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                BriefingHeader(
                    meta: "SIGNED & SAVED",
                    title: "Signed & saved",
                    line: summaryLine)
                    .padding(.top, 8)

                summaryCard

                alertAffordance

                VStack(spacing: 10) {
                    ClayButton(title: isGenerating ? "Preparing PDF…" : "Share PDF",
                               icon: "square.and.arrow.up",
                               isEnabled: !isGenerating) {
                        Task { await prepareAndShare() }
                    }
                    SecondaryButton(title: "Text to customer", icon: "message") {
                        Task { await prepareAndText() }
                    }
                }

                Spacer(minLength: 30)
            }
            .padding(.horizontal, 20)
        }
        .paperBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { onClose() }.font(.acmeBodyMed)
            }
        }
        .sheet(isPresented: $showShare) {
            if let pdfURL { ShareSheet(items: [pdfURL]) }
        }
        .sheet(isPresented: $showMessage) {
            if let pdfURL {
                MessageComposer(
                    recipients: [inspection.customerPhone].compactMap { $0 },
                    body: messageBody,
                    attachmentURL: pdfURL)
            }
        }
    }

    // MARK: - Pieces

    private var summaryLine: String {
        let who = inspection.customerName.isEmpty ? "Your customer" : inspection.customerName
        let n = inspection.marks.count
        if n == 0 {
            return "\(who) signed a clean record. You're covered if it comes up later."
        }
        return "\(who) approved \(n) pre-existing mark\(n == 1 ? "" : "s"). You're covered if it comes up later."
    }

    private var summaryCard: some View {
        ACMECard {
            VStack(alignment: .leading, spacing: 0) {
                summaryRow("Vehicle", inspection.vehicleTitle, "car.fill")
                divider
                summaryRow("Marks · photos", "\(inspection.marks.count) marks · \(totalPhotos) photos", "mappin.and.ellipse")
                divider
                summaryRowSerif("Signature", inspection.customerName.isEmpty ? "Captured" : inspection.customerName)
                divider
                summaryRow("Signed", inspection.signedAt.map(DP.full) ?? "—", "clock")
                if inspection.hasLocation, let lat = inspection.latitude, let lon = inspection.longitude {
                    divider
                    summaryRow("Location", DP.coordinate(lat: lat, lon: lon), "location.fill")
                }
            }
        }
    }

    private var divider: some View { Divider().overlay(Color.hairline).padding(.vertical, 10) }

    private func summaryRow(_ label: String, _ value: String, _ icon: String) -> some View {
        HStack(spacing: 12) {
            IconTile(systemName: icon, size: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).acmeMetaRow()
                Text(value).font(.acmeBodyMed).foregroundStyle(Color.inkPrimary)
            }
            Spacer()
        }
    }

    private func summaryRowSerif(_ label: String, _ value: String) -> some View {
        HStack(spacing: 12) {
            IconTile(systemName: "signature", size: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).acmeMetaRow()
                Text(value).font(.system(size: 18, weight: .regular, design: .serif))
                    .foregroundStyle(Color.inkPrimary)
            }
            Spacer()
        }
    }

    private var alertAffordance: some View {
        Button {
            Task { await scheduleNudge() }
        } label: {
            HStack(spacing: 12) {
                IconTile(systemName: nudgeScheduled ? "checkmark" : "bell.fill", size: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(nudgeScheduled ? "Reminder set" : "Remind me to follow up")
                        .font(.acmeBodyMed).foregroundStyle(Color.inkPrimary)
                    Text(nudgeScheduled
                         ? "We'll nudge you in 24h to check on \(firstName)."
                         : "We'll nudge you if \(firstName) hasn't opened it in 24h.")
                        .font(.acmeMeta).foregroundStyle(Color.inkSecondary)
                }
                Spacer()
            }
            .padding(14)
            .background(Color.peach.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.clay.opacity(0.35), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .disabled(nudgeScheduled)
    }

    private var firstName: String {
        let name = inspection.customerName
        return name.isEmpty ? "your customer" : (name.split(separator: " ").first.map(String.init) ?? name)
    }

    private var totalPhotos: Int {
        inspection.generalPhotos.count + inspection.marks.reduce(0) { $0 + $1.photos.count }
    }

    private var messageBody: String {
        let who = inspection.customerName.isEmpty ? "" : "Hi \(firstName), "
        return "\(who)here's the pre-service condition report for your \(inspection.vehicleTitle). Thanks!"
    }

    // MARK: - Actions

    private func ensurePDF() async {
        guard pdfURL == nil else { return }
        isGenerating = true
        let url = PDFReportGenerator.generate(for: inspection, profile: profile)
        pdfURL = url
        isGenerating = false
    }

    private func prepareAndShare() async {
        await ensurePDF()
        if pdfURL != nil { showShare = true }
    }

    private func prepareAndText() async {
        await ensurePDF()
        guard pdfURL != nil else { return }
        if MessageComposer.canSend {
            showMessage = true
        } else {
            showShare = true   // Fallback when Messages isn't available.
        }
    }

    private func scheduleNudge() async {
        let id = await NotificationService.scheduleFollowUp(customerName: inspection.customerName)
        if id != nil {
            Haptics.success()
            nudgeScheduled = true
        }
    }
}
