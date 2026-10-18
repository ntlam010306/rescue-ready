import Foundation

/// Allergens that must be declared under the Australia New Zealand Food Standards Code.
enum Allergen: String, CaseIterable, Codable, Hashable {
    case gluten
    case wheat
    case crustacean
    case mollusc
    case egg
    case fish
    case milk
    case peanut
    case treeNut
    case sesame
    case soy
    case lupin
    case sulphites

    var displayName: String {
        switch self {
        case .gluten: return "Gluten"
        case .wheat: return "Wheat"
        case .crustacean: return "Crustacea"
        case .mollusc: return "Molluscs"
        case .egg: return "Egg"
        case .fish: return "Fish"
        case .milk: return "Milk"
        case .peanut: return "Peanut"
        case .treeNut: return "Tree nuts"
        case .sesame: return "Sesame"
        case .soy: return "Soy"
        case .lupin: return "Lupin"
        case .sulphites: return "Sulphites"
        }
    }
}
