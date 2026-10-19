import SwiftUI

/// Log a pickup at an event and add the batches collected.
struct PickupLogView: View {
    @State private var viewModel: PickupViewModel
    @State private var isAddingBatch = false

    init(viewModel: PickupViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Log Pickup")
                .task { await viewModel.load() }
                .sheet(isPresented: $isAddingBatch) {
                    AddBatchView { viewModel.addBatch($0) }
                }
                .alert("Pickup saved", isPresented: isShowingSaved) {
                    Button("OK") { viewModel.dismissSaveResult() }
                } message: {
                    Text("The batches are ready for safety checks.")
                }
                .alert("Couldn't save pickup", isPresented: isShowingSaveError) {
                    Button("OK") { viewModel.dismissSaveResult() }
                } message: {
                    Text(saveErrorMessage)
                }
                .sensoryFeedback(.success, trigger: viewModel.saveState == .saved)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .loading:
            ProgressView("Loading events")
        case .failed(let message):
            ContentUnavailableView {
                Label("Couldn't load events", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") { Task { await viewModel.load() } }
            }
        case .loaded where viewModel.events.isEmpty:
            ContentUnavailableView(
                "No active events",
                systemImage: "calendar.badge.exclamationmark",
                description: Text("Pickups can be logged from the start of an event until 3 hours after it ends.")
            )
        case .loaded:
            form
        }
    }

    private var form: some View {
        Form {
            Section("Event") {
                Picker("Event", selection: $viewModel.selectedEventID) {
                    ForEach(viewModel.events) { event in
                        VStack(alignment: .leading) {
                            Text(event.name)
                            Text(event.venue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(Optional(event.id))
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section {
                if viewModel.batches.isEmpty {
                    Text("No batches yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.batches) { batch in
                        BatchDraftRow(batch: batch)
                    }
                    .onDelete { viewModel.removeBatches(at: $0) }
                }
                Button {
                    isAddingBatch = true
                } label: {
                    Label("Add Batch", systemImage: "plus")
                }
            } header: {
                Text("Batches")
            } footer: {
                if !viewModel.batches.isEmpty {
                    Text("\(viewModel.batches.count) batches, \(viewModel.totalWeightKg.kilogramsText) in total")
                }
            }

            Section {
                Button {
                    Task { await viewModel.save() }
                } label: {
                    if viewModel.saveState == .saving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Save Pickup")
                    }
                }
                .buttonStyle(.primary)
                .disabled(!viewModel.canSave)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
    }

    private var isShowingSaved: Binding<Bool> {
        Binding(
            get: { viewModel.saveState == .saved },
            set: { if !$0 { viewModel.dismissSaveResult() } }
        )
    }

    private var isShowingSaveError: Binding<Bool> {
        Binding(
            get: { if case .failed = viewModel.saveState { return true } else { return false } },
            set: { if !$0 { viewModel.dismissSaveResult() } }
        )
    }

    private var saveErrorMessage: String {
        if case .failed(let message) = viewModel.saveState { return message }
        return ""
    }
}

private struct BatchDraftRow: View {
    let batch: NewBatch

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(batch.foodDescription)
                    .font(.body.weight(.medium))
                Spacer()
                Text(batch.weightKg.kilogramsText)
                    .foregroundStyle(.secondary)
            }
            Text(allergenSummary)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var allergenSummary: String {
        guard batch.allergensDeclared else { return "Allergens not confirmed" }
        guard !batch.allergens.isEmpty else { return "No allergens" }
        return "Contains " + batch.allergens.map(\.displayName).sorted().joined(separator: ", ")
    }
}

#Preview {
    PickupLogView(viewModel: AppContainer.preview().makePickupViewModel())
}
