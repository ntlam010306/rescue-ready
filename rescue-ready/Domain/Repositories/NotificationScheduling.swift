import Foundation

/// Whether the user has allowed the app to send notifications.
enum NotificationPermission: Equatable {
    case notDetermined
    case denied
    case authorized
}

/// Schedules local alerts. Keeps use cases independent of the UserNotifications framework.
protocol NotificationScheduling {
    func permission() async -> NotificationPermission

    /// Shows the system permission prompt if needed. Returns true when alerts are allowed.
    func requestPermission() async -> Bool

    /// Schedules (or replaces) the expiry alert for a batch.
    func scheduleExpiryAlert(for batch: FoodBatch, at date: Date) async throws

    /// Removes any pending expiry alert for a batch. Does nothing if none is pending.
    func cancelExpiryAlert(for batchID: Identifier<FoodBatch>) async
}
