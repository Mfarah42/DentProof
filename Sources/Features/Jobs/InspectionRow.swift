import SwiftUI

/// A single cream row: icon tile → vehicle + customer/time → status chip.
struct InspectionRow: View {
    let inspection: Inspection

    var body: some View {
        HStack(spacing: 12) {
            IconTile(systemName: "car.fill", size: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(inspection.vehicleTitle)
                    .font(.acmeBodyMed)
                    .foregroundStyle(Color.inkPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.acmeMeta)
                    .foregroundStyle(Color.inkSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            StatusChip(status: inspection.status, marks: inspection.marks.count)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var subtitle: String {
        let who = inspection.customerName.isEmpty ? "No name" : inspection.customerName
        return "\(DP.time(inspection.createdAt)) · \(who)"
    }
}

struct StatusChip: View {
    let status: InspectionStatus
    let marks: Int

    var body: some View {
        let (label, color): (String, Color) = {
            switch status {
            case .signed: return ("Signed", .clayDeep)
            case .draft:  return ("Draft", .inkSecondary)
            }
        }()
        return Text(label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(color.opacity(0.12))
            )
    }
}
