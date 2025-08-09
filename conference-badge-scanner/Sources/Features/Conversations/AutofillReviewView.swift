import SwiftUI
import UIKit

/// Review and correct per-field OCR results before applying to form fields.
struct AutofillReviewView: View {
    @Environment(\.dismiss) private var dismiss

    let event: Event
    let originalImage: UIImage?
    let rawText: String

    // Starting values keyed by BadgeField
    @State private var values: [BadgeField: String]
    @State private var confidences: [BadgeField: Double]

    var onApply: (Dictionary<BadgeField, String>) -> Void
    var onCancel: () -> Void

    init(event: Event,
         originalImage: UIImage?,
         rawText: String,
         mappedByKey: [String: String],
         onApply: @escaping (Dictionary<BadgeField, String>) -> Void,
         onCancel: @escaping () -> Void) {
        self.event = event
        self.originalImage = originalImage
        self.rawText = rawText
        self.onApply = onApply
        self.onCancel = onCancel

        // Initialize from mapping, filtered to selected badge fields
        var initial: [BadgeField: String] = [:]
        var conf: [BadgeField: Double] = [:]
        let selected = event.selectedBadgeFields
        for field in selected {
            if let t = mappedByKey[field.rawValue] {
                initial[field] = t
                conf[field] = nil // placeholder until we compute
            }
        }
        _values = State(initialValue: initial)
        _confidences = State(initialValue: conf)
    }

    var body: some View {
        NavigationStack {
            Form {
                if let image = originalImage {
                    Section("Image") {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
                Section("Autofill") {
                    ForEach(event.selectedBadgeFields) { field in
                        HStack(alignment: .firstTextBaseline) {
                            TextField(field.displayName, text: Binding<String>(
                                get: { values[field] ?? "" },
                                set: { values[field] = $0 }
                            ))
                            if let c = confidences[field] {
                                ConfidencePill(confidence: c)
                            }
                        }
                    }
                }
                Section("OCR Text") {
                    Text(rawText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationTitle("Review Autofill")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .destructive) { onCancel(); dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply(values)
                        dismiss()
                    }
                }
            }
            .task {
                // Compute confidences by running region OCR detailed for selected fields
                // We only compute for fields we have initial values for
                guard let image = originalImage else { return }
                let regions = event.badgeFieldRegionsMap
                var map: [String: NormalizedRect] = [:]
                for field in event.selectedBadgeFields {
                    if values[field] != nil, let rect = regions[field.rawValue] { map[field.rawValue] = rect }
                }
                if map.isEmpty { return }
                OCRProcessor.recognizeTextDetailed(in: image, regionsByKey: map) { results in
                    var updated: [BadgeField: Double] = confidences
                    for (key, pair) in results {
                        let (text, conf) = pair
                        // Only set confidence if text matches current value (to avoid confusing signal after edits)
                        if let field = BadgeField(rawValue: key), values[field] == text {
                            updated[field] = conf
                        } else if let field = BadgeField(rawValue: key) {
                            updated[field] = conf // still show; user may have edited slightly
                        }
                    }
                    confidences = updated
                }
            }
        }
    }
}


