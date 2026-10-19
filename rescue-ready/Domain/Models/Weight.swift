import Foundation

/// A validated batch weight in kilograms.
struct Weight: Equatable {
    static let maximumKilograms: Double = 500

    let kilograms: Double

    init(kilograms: Double) throws {
        guard kilograms > 0, kilograms <= Self.maximumKilograms else {
            throw DomainError.invalidWeight
        }
        self.kilograms = kilograms
    }
}
