import Foundation

final class InMemoryDropPointRepository: DropPointRepository {
    private let store: InMemoryDataStore
    /// Set to true to make every call throw, for testing error handling.
    var shouldFail = false

    init(store: InMemoryDataStore = InMemoryDataStore()) {
        self.store = store
    }

    func all() async throws -> [DropPoint] {
        if shouldFail { throw RepositoryError.fetchFailed }
        return store.dropPoints.values.sorted { $0.name < $1.name }
    }

    func dropPoint(id: Identifier<DropPoint>) async throws -> DropPoint? {
        if shouldFail { throw RepositoryError.fetchFailed }
        return store.dropPoints[id]
    }
}
