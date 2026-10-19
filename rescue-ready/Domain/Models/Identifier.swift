import Foundation

/// A strongly typed identifier.
///
/// The phantom `Entity` parameter stops IDs being mixed up at compile time:
/// an `Identifier<FoodBatch>` can never be passed where an `Identifier<Pickup>` is expected.
struct Identifier<Entity>: Hashable {
    let rawValue: UUID

    init(_ rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}
