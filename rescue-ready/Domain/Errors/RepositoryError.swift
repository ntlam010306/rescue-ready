import Foundation

/// Storage-level failures thrown by repositories.
///
/// Use cases translate these into `DomainError.storageFailure` so that
/// views never see storage details.
enum RepositoryError: Error, Equatable {
    case notFound
    case saveFailed
    case fetchFailed
}
