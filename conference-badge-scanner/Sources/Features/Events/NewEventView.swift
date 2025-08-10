import SwiftUI

struct NewEventView: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (String, Date, Date?, String?, String?, String?) -> Void

    @State private var name = ""
    @State private var dateRange: DateInterval? = nil
    @State private var location: String = ""
    @State private var details: String = ""
    @State private var website: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Event Name") {
                    ClearableTextField("Event name", text: $name)
                }
                Section("Schedule") {
                    if #available(iOS 16.0, *) {
                        GroupBox {
                            CalendarRangePicker(range: $dateRange)
                                .scaleEffect(0.92)
                                .contentShape(Rectangle())
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 0)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 28, bottom: 0, trailing: 28))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    } else {
                        DatePicker(
                            "Start",
                            selection: Binding(
                                get: { dateRange?.start ?? Date() },
                                set: { newStart in
                                    let currentEnd = dateRange?.end ?? newStart
                                    let end = max(currentEnd, newStart)
                                    dateRange = DateInterval(start: newStart, end: end)
                                }
                            ),
                            displayedComponents: [.date]
                        )
                        DatePicker(
                            "End",
                            selection: Binding(
                                get: { dateRange?.end ?? (dateRange?.start ?? Date()) },
                                set: { newEnd in
                                    let start = dateRange?.start ?? newEnd
                                    let end = max(newEnd, start)
                                    dateRange = DateInterval(start: start, end: end)
                                }
                            ),
                            displayedComponents: [.date]
                        )
                    }
                }
                Section("Details") {
                    ClearableTextField("Details (optional)", text: $details, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
                Section("Website & Location") {
                    ClearableTextField("Website (optional)", text: $website)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    ClearableTextField("Location (address, optional)", text: $location)
                }
            }
            .listSectionSpacing(8)
            .navigationTitle("New Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let now = Date()
                        let start = dateRange?.start ?? now
                        let end = dateRange?.end
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


