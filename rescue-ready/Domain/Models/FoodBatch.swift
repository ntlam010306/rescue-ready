import Foundation

/// A single container or tray of one food item within a pickup.
struct FoodBatch: Identifiable, Equatable {
    let id: Identifier<FoodBatch>
    let pickupID: Identifier<Pickup>
    var foodDescription: String
    var weight: Weight
    var allergens: Set<Allergen>
    /// True once the volunteer has confirmed the allergen list, even if it is empty.
    var allergensDeclared: Bool
    var holdWindow: HoldWindow
    var status: BatchStatus
    var dropPointID: Identifier<DropPoint>?
    var discardReason: String?
}
