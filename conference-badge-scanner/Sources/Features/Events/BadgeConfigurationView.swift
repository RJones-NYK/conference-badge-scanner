import SwiftUI

struct BadgeConfigurationView: View {
    @Environment(\.dismiss) private var dismiss

    let event: Event

    @State private var selectedFields: Set<BadgeField> = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Badge Fields") { badgeFieldsGrid }
                Section("Preview") { badgePreview }
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

    private var badgeFieldsGrid: some View {
        let columns: [GridItem] = [GridItem(.adaptive(minimum: 120), spacing: 12)]
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(BadgeField.allCases) { field in
                let isOn = selectedFields.contains(field)
                Button { toggle(field, isOn: isOn) } label: {
                    BadgeFieldChip(title: field.displayName, selected: isOn)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private func toggle(_ field: BadgeField, isOn: Bool) {
        if isOn { selectedFields.remove(field) } else { selectedFields.insert(field) }
    }

    private var badgePreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
            VStack(spacing: 8) {
                Text("Conference Badge").font(.headline)
                ForEach(BadgeField.allCases.filter { selectedFields.contains($0) }) { field in
                    Text(field.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if selectedFields.isEmpty {
                    Text("No fields selected").foregroundStyle(.secondary)
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, minHeight: 140)
    }
}

private struct BadgeFieldChip: View {
    let title: String
    let selected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: selected ? "checkmark.seal.fill" : "seal")
            Text(title)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(selected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
        .foregroundStyle(selected ? Color.accentColor : .primary)
        .clipShape(Capsule())
    }
}


