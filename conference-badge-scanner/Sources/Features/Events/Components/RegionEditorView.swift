import SwiftUI

struct RegionEditorView: View {
    let image: UIImage
    let fields: [BadgeField]
    @Binding var regions: [String: NormalizedRect]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                RegionSelectionCanvas(image: image, fields: fields, regions: $regions)
                    .padding()
            }
            .navigationTitle("Define Regions")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .background(Color(.systemBackground))
        }
    }
}


