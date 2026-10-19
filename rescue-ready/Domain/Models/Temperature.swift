import Foundation

/// A validated food temperature reading in degrees Celsius.
struct Temperature: Equatable {
    /// Below 5°C and above 60°C are safe; anything in between is the danger zone
    /// where bacteria grow fastest.
    static let dangerZone: ClosedRange<Double> = 5.0...60.0

    /// Readings outside this range are treated as probe or input errors.
    static let plausibleRange: ClosedRange<Double> = -30.0...120.0

    let celsius: Double

    init(celsius: Double) throws {
        guard Self.plausibleRange.contains(celsius) else {
            throw DomainError.invalidTemperatureReading
        }
        self.celsius = celsius
    }

    /// True when the food is strictly between 5°C and 60°C.
    var isInDangerZone: Bool {
        celsius > Self.dangerZone.lowerBound && celsius < Self.dangerZone.upperBound
    }
}
