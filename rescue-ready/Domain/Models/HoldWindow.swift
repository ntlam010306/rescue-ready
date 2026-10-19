import Foundation

/// The time a batch may stay out of temperature control before it must be discarded.
///
/// Follows the 2-hour / 4-hour rule: food held between 5°C and 60°C for more than
/// 4 hours in total must not be served.
struct HoldWindow: Equatable {
    static let maximumDuration: TimeInterval = 4 * 60 * 60

    let startedAt: Date

    var expiresAt: Date {
        startedAt.addingTimeInterval(Self.maximumDuration)
    }

    func hasExpired(at now: Date) -> Bool {
        now >= expiresAt
    }

    /// Time left before the window closes. Never negative.
    func remaining(at now: Date) -> TimeInterval {
        max(0, expiresAt.timeIntervalSince(now))
    }
}
