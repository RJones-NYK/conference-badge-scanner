import SwiftUI

/// A text field that shows a trailing clear (x) button when it has content.
/// Supports both single-line and multi-line (axis) configurations.
struct ClearableTextField: View {
    let title: String
    @Binding var text: String
    let axis: Axis?

    init(_ title: String, text: Binding<String>, axis: Axis? = nil) {
        self.title = title
        self._text = text
        self.axis = axis
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            if let axis = axis {
                TextField(title, text: $text, axis: axis)
            } else {
                TextField(title, text: $text)
            }

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 6)
            }
        }
    }
}


