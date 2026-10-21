import SwiftUI

/// Open batches, soonest safe hold deadline first, with the time left on each.
struct BatchListView: View {
    @State private var viewModel: BatchListViewModel

    init(viewModel: BatchListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Batches")
                .task { await viewModel.load() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .loading:
            ProgressView("Loading batches")
        case .failed(let message):
            ContentUnavailableView {
                Label("Couldn't load batches", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") { Task { await viewModel.load() } }
            }
        case .loaded:
            list
        }
    }

    private var list: some View {
        List {
            if viewModel.notificationsDenied {
                NotificationsDeniedBanner()
            }

            if viewModel.batches.isEmpty {
                ContentUnavailableView(
                    "No open batches",
                    systemImage: "tray",
                    description: Text("Batches from your pickups will appear here until they are handed over or discarded.")
                )
                .listRowBackground(Color.clear)
            } else {
                // Redraws every minute so the time left stays current while the screen is open.
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    ForEach(viewModel.batches) { item in
                        BatchRow(batch: item.batch, timeRemaining: item.batch.holdWindow.remaining(at: context.date))
                    }
                }
            }
        }
        .refreshable { await viewModel.load() }
    }
}

// MARK: - Rows

private struct BatchRow: View {
    let batch: FoodBatch
    let timeRemaining: TimeInterval

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(batch.foodDescription)
                    .font(.headline)
                Spacer()
                Text(batch.weight.kilograms.kilogramsText)
                    .foregroundStyle(.secondary)
            }
            HStack {
                StatusBadge(status: batch.status)
                Spacer()
                Label(timeText, systemImage: timeSymbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(timeColor)
            }
        }
        .padding(.vertical, 4)
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
    }

    private var isUrgent: Bool { timeRemaining < 30 * 60 }

    private var timeText: String {
        guard timeRemaining > 0 else { return "Expired" }
        let left = Duration.seconds(timeRemaining)
            .formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
        return "\(left) left"
    }

    private var timeSymbol: String {
        if timeRemaining <= 0 { return "xmark.circle" }
        return isUrgent ? "exclamationmark.triangle" : "timer"
    }

    private var timeColor: Color {
        if timeRemaining <= 0 { return .red }
        return isUrgent ? .orange : .secondary
    }
}

/// Explains that expiry alerts are off, with a shortcut to turn them back on.
private struct NotificationsDeniedBanner: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Expiry alerts are off", systemImage: "bell.slash")
                .font(.headline)
            Text("You won't be warned before a batch runs out of safe hold time. Keep an eye on this list, or turn notifications on in Settings.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            .frame(minHeight: 44)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Previews

#Preview("Batches") {
    BatchListView(viewModel: .preview())
}

#Preview("Alerts off") {
    BatchListView(viewModel: .preview(permission: .denied))
        .preferredColorScheme(.dark)
}

extension BatchListViewModel {
    /// A view model backed by sample data, for SwiftUI previews.
    static func preview(permission: NotificationPermission = .authorized) -> BatchListViewModel {
        let now = Date()
        let store = SampleData.makeStore(now: now)
        return BatchListViewModel(
            fetchExpiringBatches: FetchExpiringBatchesUseCase(batches: InMemoryBatchRepository(store: store),
                                                              now: { now }),
            notifications: InMemoryNotificationScheduler(permission: permission)
        )
    }
}
