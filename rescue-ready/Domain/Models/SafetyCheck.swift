import Foundation

/// The result of a safety check.
enum SafetyOutcome: Equatable {
    case passed
    case failed(reason: String)

    var isPassed: Bool {
        if case .passed = self { return true }
        return false
    }
}

/// A recorded temperature and allergen check for a batch.
struct SafetyCheck: Identifiable, Equatable {
    let id: Identifier<SafetyCheck>
    let batchID: Identifier<FoodBatch>
    let temperature: Temperature
    let checkedAt: Date
    let outcome: SafetyOutcome
}
