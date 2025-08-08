import SwiftUI

struct BadgeConfigurationView: View {
    @Environment(\.dismiss) private var dismiss

    let event: Event

    @State private var selectedFields: Set<BadgeField> = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Badge Fields") {
                    ForEach(BadgeField.allCases) { field in
                        Toggle(isOn: Binding(
                            get: { selectedFields.contains(field) },
                            set: { isOn in
                                if isOn { selectedFields.insert(field) } else { selectedFields.remove(field) }
                            }
                        )) {
                            Text(field.displayName)
                        }
                    }
                }
            }
            .navigationTitle("Configure Badge")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let ordered = BadgeField.allCases.filter { selectedFields.contains($0) }
                        event.badgeFieldKeys = ordered.map { $0.rawValue }
                        dismiss()
                    }
                }
            }
            .onAppear {
                let current = Set(event.badgeFieldKeys.compactMap(BadgeField.init(rawValue:)))
                if current.isEmpty {
                    selectedFields = Set(BadgeField.defaultSelection)
                } else {
                    selectedFields = current
                }
            }
        }
    }
}


