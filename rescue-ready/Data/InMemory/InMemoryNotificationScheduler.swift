import Foundation

/// Records alerts instead of scheduling them, so tests can check what happened.
final class InMemoryNotificationScheduler: NotificationScheduling {
    var currentPermission: NotificationPermission
    /// Permission granted when `requestPermission()` is called while not yet determined.
    var grantsPermissionOnRequest: Bool
    /// Set to true to make scheduling throw.
    var shouldFail = false

    private(set) var scheduledAlerts: [Identifier<FoodBatch>: Date] = [:]
    private(set) var cancelledBatchIDs: [Identifier<FoodBatch>] = []
    private(set) var permissionRequestCount = 0

    init(permission: NotificationPermission = .authorized, grantsPermissionOnRequest: Bool = true) {
        self.currentPermission = permission
        self.grantsPermissionOnRequest = grantsPermissionOnRequest
    }

    func permission() async -> NotificationPermission {
        currentPermission
    }

    func requestPermission() async -> Bool {
        permissionRequestCount += 1
        if currentPermission == .notDetermined {
            currentPermission = grantsPermissionOnRequest ? .authorized : .denied
        }
        return currentPermission == .authorized
    }

    func scheduleExpiryAlert(for batch: FoodBatch, at date: Date) async throws {
        if shouldFail { throw RepositoryError.saveFailed }
        scheduledAlerts[batch.id] = date
    }

    func cancelExpiryAlert(for batchID: Identifier<FoodBatch>) async {
        scheduledAlerts[batchID] = nil
        cancelledBatchIDs.append(batchID)
    }
}
