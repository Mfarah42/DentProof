import UserNotifications

/// Local-only notifications. v1 uses exactly one: a 24h "nudge" reminder the
/// detailer can opt into after texting a report.
enum NotificationService {

    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        default:
            return false
        }
    }

    /// Schedules a follow-up nudge ~24h out. Returns the identifier so the
    /// caller can cancel it later if needed.
    @discardableResult
    static func scheduleFollowUp(customerName: String, after seconds: TimeInterval = 24 * 60 * 60) async -> String? {
        guard await requestAuthorizationIfNeeded() else { return nil }

        let content = UNMutableNotificationContent()
        content.title = "Follow up on the report"
        let who = customerName.isEmpty ? "your customer" : customerName
        content.body = "Check whether \(who) has opened the inspection you sent."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(60, seconds), repeats: false)
        let id = "followup-\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            return id
        } catch {
            return nil
        }
    }

    static func cancel(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}
