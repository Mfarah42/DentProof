import SwiftData
import Foundation

@Model final class BusinessProfile {
    var name: String = ""
    var phone: String?
    var email: String?
    var logoPath: String?          // relative path in Documents
    var isPro: Bool = false        // cached mirror of StoreKit entitlement
    init() {}
}

@Model final class Inspection {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var customerName: String = ""
    var customerPhone: String?
    var vehicleMake: String = ""
    var vehicleModel: String = ""
    var vehicleColor: String = ""
    var vehiclePlate: String?
    var bodyStyleRaw: String = BodyStyle.sedan.rawValue
    var statusRaw: String = InspectionStatus.draft.rawValue
    var signedAt: Date?
    var signaturePath: String?     // PNG of signature on disk
    var latitude: Double?
    var longitude: Double?

    @Relationship(deleteRule: .cascade, inverse: \DamageMark.inspection)
    var marks: [DamageMark] = []

    @Relationship(deleteRule: .cascade, inverse: \InspectionPhoto.inspection)
    var generalPhotos: [InspectionPhoto] = []

    init() {}

    // Type-safe accessors over the stored raw strings (SwiftData stores enums
    // fine, but raw strings keep migrations painless and avoid edge cases).
    var bodyStyle: BodyStyle {
        get { BodyStyle(rawValue: bodyStyleRaw) ?? .sedan }
        set { bodyStyleRaw = newValue.rawValue }
    }
    var status: InspectionStatus {
        get { InspectionStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }

    var vehicleTitle: String {
        let parts = [vehicleMake, vehicleModel].filter { !$0.isEmpty }
        return parts.isEmpty ? "Vehicle" : parts.joined(separator: " ")
    }

    var marksSorted: [DamageMark] {
        marks.sorted { $0.index < $1.index }
    }

    var hasLocation: Bool { latitude != nil && longitude != nil }
}

@Model final class DamageMark {
    var id: UUID = UUID()
    var index: Int = 0             // 1,2,3 label
    var typeRaw: String = DamageType.scratch.rawValue
    var locationLabel: String = "" // "L front door"
    var note: String?
    var x: Double = 0.5            // NORMALIZED 0…1 on the diagram
    var y: Double = 0.5            // normalized so it scales + re-renders in the PDF

    var inspection: Inspection?

    @Relationship(deleteRule: .cascade, inverse: \InspectionPhoto.mark)
    var photos: [InspectionPhoto] = []

    init() {}

    var type: DamageType {
        get { DamageType(rawValue: typeRaw) ?? .scratch }
        set { typeRaw = newValue.rawValue }
    }
}

@Model final class InspectionPhoto {
    var id: UUID = UUID()
    var path: String = ""          // relative path in Documents
    var createdAt: Date = Date()

    var inspection: Inspection?    // set when a "general" before photo
    var mark: DamageMark?          // set when tied to a specific mark

    init() {}
}
