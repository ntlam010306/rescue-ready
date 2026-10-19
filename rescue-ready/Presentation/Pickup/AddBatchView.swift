import SwiftUI

/// Sheet for entering one batch: food, weight and allergens.
struct AddBatchView: View {
    let onAdd: (NewBatch) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var foodDescription = ""
    @State private var weightText = ""
    @State private var allergens: Set<Allergen> = []
    @State private var allergensConfirmed = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case description
        case weight
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Food") {
                    TextField("Description, for example Vegetable fried rice", text: $foodDescription)
                        .focused($focusedField, equals: .description)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .weight }

                    TextField("Weight in kg", text: $weightText)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .weight)
                }

                Section("Allergens") {
                    ForEach(Allergen.allCases, id: \.self) { allergen in
                        Toggle(allergen.displayName, isOn: binding(for: allergen))
                    }
                }

                Section {
                    Toggle("Allergens checked with the venue", isOn: $allergensConfirmed)
                } footer: {
                    Text("A batch can't pass its safety check until its allergens are confirmed.")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Batch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { add() }
                        .disabled(!canAdd)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
            .onAppear { focusedField = .description }
        }
    }

    /// Accepts "5.5" and "5,5". Full validation happens in the use case.
    private var weightKg: Double? {
        Double(weightText.replacingOccurrences(of: ",", with: "."))
    }

    private var canAdd: Bool {
        !foodDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (weightKg ?? 0) > 0
    }

    private func binding(for allergen: Allergen) -> Binding<Bool> {
        Binding(
            get: { allergens.contains(allergen) },
            set: { isOn in
                if isOn {
                    allergens.insert(allergen)
                } else {
                    allergens.remove(allergen)
                }
            }
        )
    }

    private func add() {
        guard let weightKg else { return }
        onAdd(NewBatch(
            foodDescription: foodDescription,
            weightKg: weightKg,
            allergens: allergens,
            allergensDeclared: allergensConfirmed
        ))
        dismiss()
    }
}

#Preview {
    AddBatchView { _ in }
}
