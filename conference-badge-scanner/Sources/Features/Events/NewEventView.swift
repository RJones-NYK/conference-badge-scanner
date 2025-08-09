import SwiftUI

struct NewEventView: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (String, Date, Date?, String?, String?, String?) -> Void

    @State private var name = ""
    @State private var start = Date()
    @State private var end: Date = Date()
    @State private var location: String = ""
    @State private var details: String = ""
    @State private var website: String = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Event name", text: $name)
                DatePicker("Start", selection: $start, displayedComponents: [.date])
                DatePicker(
                    "End",
                    selection: Binding(
                        get: { max(end, start) },
                        set: { end = max($0, start) }
                    ),
                    displayedComponents: [.date]
                )
                TextField("Details (optional)", text: $details, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
                TextField("Website (optional)", text: $website)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                TextField("Location (address, optional)", text: $location)
            }
            .navigationTitle("New Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(
                            name.trimmingCharacters(in: .whitespaces),
                            start,
                            end,
                            location.isEmpty ? nil : location,
                            details.isEmpty ? nil : details,
                            website.isEmpty ? nil : website
                        )
                        dismiss()
                    }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// Intentionally no generic Binding extension to avoid ambiguity across Swift toolchains


