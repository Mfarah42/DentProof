import SwiftUI
import UserNotifications

struct AlertsView: View {
    @State private var pending: [UNNotificationRequest] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                BriefingHeader(
                    meta: "FOLLOW-UPS",
                    title: "Alerts",
                    line: pending.isEmpty
                        ? "No reminders set. Add one from a signed report to nudge yourself later."
                        : "\(pending.count) follow-up reminder\(pending.count == 1 ? "" : "s") scheduled.")
                    .padding(.top, 20)

                if pending.isEmpty {
                    ACMECard {
                        VStack(alignment: .leading, spacing: 8) {
                            IconTile(systemName: "bell.fill", size: 40)
                            Text("Quiet for now")
                                .font(.acmeSection)
                                .foregroundStyle(Color.inkPrimary)
                            Text("When you finish a report, tap \"Remind me to follow up\" and it'll show here.")
                                .font(.acmeBody)
                                .foregroundStyle(Color.inkSecondary)
                        }
                    }
                } else {
                    ACMECard(padding: 8) {
                        VStack(spacing: 0) {
                            ForEach(Array(pending.enumerated()), id: \.element.identifier) { idx, req in
                                alertRow(req)
                                if idx < pending.count - 1 { Divider().overlay(Color.hairline) }
                            }
                        }
                    }
                }

                Spacer(minLength: 90)
            }
            .padding(.horizontal, 20)
        }
        .paperBackground()
        .task { await reload() }
    }

    private func alertRow(_ req: UNNotificationRequest) -> some View {
        HStack(spacing: 12) {
            IconTile(systemName: "bell.fill", size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(req.content.body)
                    .font(.acmeBody)
                    .foregroundStyle(Color.inkPrimary)
                    .lineLimit(2)
                if let trigger = req.trigger as? UNTimeIntervalNotificationTrigger,
                   let date = trigger.nextTriggerDate() {
                    Text("Fires \(DP.full(date))")
                        .font(.acmeMeta)
                        .foregroundStyle(Color.inkSecondary)
                }
            }
            Spacer()
            Button {
                NotificationService.cancel(id: req.identifier)
                Task { await reload() }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.inkSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8).padding(.vertical, 10)
    }

    private func reload() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        pending = requests.sorted {
            let a = ($0.trigger as? UNTimeIntervalNotificationTrigger)?.nextTriggerDate() ?? .distantFuture
            let b = ($1.trigger as? UNTimeIntervalNotificationTrigger)?.nextTriggerDate() ?? .distantFuture
            return a < b
        }
    }
}
