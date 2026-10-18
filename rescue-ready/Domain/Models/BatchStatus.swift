import Foundation

/// Where a batch is in its lifecycle.
///
///     awaitingCheck --> cleared ------> handedOver
///           |              |
///           v              v
///      failedCheck ---> discarded
enum BatchStatus: String, Codable, CaseIterable {
    case awaitingCheck
    case cleared
    case failedCheck
    case handedOver
    case discarded

    /// Open batches still need action from a volunteer.
    var isOpen: Bool {
        switch self {
        case .awaitingCheck, .cleared, .failedCheck: return true
        case .handedOver, .discarded: return false
        }
    }

    var displayName: String {
        switch self {
        case .awaitingCheck: return "Awaiting check"
        case .cleared: return "Cleared"
        case .failedCheck: return "Failed check"
        case .handedOver: return "Handed over"
        case .discarded: return "Discarded"
        }
    }
}
