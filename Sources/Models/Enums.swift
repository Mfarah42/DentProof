import Foundation

enum BodyStyle: String, Codable, CaseIterable, Identifiable {
    case sedan, suv, truck, coupe, van, other
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sedan: return "Sedan"
        case .suv:   return "SUV"
        case .truck: return "Truck"
        case .coupe: return "Coupe"
        case .van:   return "Van"
        case .other: return "Other"
        }
    }
}

enum DamageType: String, Codable, CaseIterable, Identifiable {
    case scratch, dent, chip, crack, stain, missingTrim, other
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .scratch:     return "Scratch"
        case .dent:        return "Dent"
        case .chip:        return "Chip"
        case .crack:       return "Crack"
        case .stain:       return "Stain"
        case .missingTrim: return "Missing trim"
        case .other:       return "Other"
        }
    }

    /// SF Symbol used inside the IconTile for this damage type.
    var symbol: String {
        switch self {
        case .scratch:     return "scribble.variable"
        case .dent:        return "circle.bottomhalf.filled"
        case .chip:        return "triangle.fill"
        case .crack:       return "bolt.fill"
        case .stain:       return "drop.fill"
        case .missingTrim: return "rectangle.dashed"
        case .other:       return "questionmark"
        }
    }
}

enum InspectionStatus: String, Codable {
    case draft, signed
}
