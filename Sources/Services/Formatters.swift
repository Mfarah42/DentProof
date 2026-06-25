import Foundation

enum DP {
    /// "TUE · 24 JUN"
    static func metaDate(_ date: Date = Date()) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE · dd MMM"
        return f.string(from: date).uppercased()
    }

    /// "2:14 PM"
    static func time(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: date)
    }

    /// "24 Jun 2026, 2:14 PM"
    static func full(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy, h:mm a"
        return f.string(from: date)
    }

    /// "Today", "Yesterday", or "24 Jun"
    static func relativeDay(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = "dd MMM"
        return f.string(from: date)
    }

    static func coordinate(lat: Double, lon: Double) -> String {
        String(format: "%.4f, %.4f", lat, lon)
    }
}
