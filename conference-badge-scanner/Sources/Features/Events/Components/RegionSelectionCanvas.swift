import SwiftUI

/// A simple image-based canvas that lets users draw and edit normalized rectangles,
/// and assign each to a `BadgeField`.
struct RegionSelectionCanvas: View {
    let image: UIImage
    let fields: [BadgeField]
    @Binding var regions: [String: NormalizedRect]

    @State private var selectedFieldIndex: Int = 0
    @State private var currentRect: CGRect? = nil
    @State private var imageSize: CGSize = .zero

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Field", selection: $selectedFieldIndex) {
                ForEach(fields.indices, id: \.self) { idx in
                    Text(fields[idx].displayName).tag(idx)
                }
            }
            .pickerStyle(.segmented)

            GeometryReader { proxy in
                let available = proxy.size
                let uiSize = fittedSize(for: image, in: available)
                ZStack(alignment: .topLeading) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: uiSize.width, height: uiSize.height)
                        .background(
                            GeometryReader { gp in
                                Color.clear.onAppear { imageSize = gp.size }
                            }
                        )
                        .gesture(drawingGesture(in: uiSize))

                    // Existing region overlay
                    ForEach(fields, id: \.rawValue) { field in
                        if let rect = regions[field.rawValue] {
                            Rectangle()
                                .stroke(fieldColor(field), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                                .frame(width: CGFloat(rect.width) * uiSize.width,
                                       height: CGFloat(rect.height) * uiSize.height)
                                .position(x: CGFloat(rect.x + rect.width/2) * uiSize.width,
                                          y: CGFloat(rect.y + rect.height/2) * uiSize.height)
                                .allowsHitTesting(false)
                        }
                    }

                    if let rect = currentRect {
                        Rectangle()
                            .fill(Color.accentColor.opacity(0.15))
                            .overlay(
                                Rectangle().stroke(Color.accentColor, lineWidth: 2)
                            )
                            .frame(width: rect.width, height: rect.height)
                            .position(x: rect.midX, y: rect.midY)
                            .allowsHitTesting(false)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }

            HStack {
                Button { clearSelected() } label: {
                    Label("Clear Selected Field", systemImage: "xmark.circle")
                }
                .disabled(fields.isEmpty)

                Spacer()

                Button { fitToExisting() } label: {
                    Label("Fit Box", systemImage: "rectangle.compress.vertical")
                }
                .disabled(fields.isEmpty || regions[fields[selectedFieldIndex].rawValue] == nil)
            }
        }
        .onChange(of: selectedFieldIndex) { _, _ in currentRect = nil }
    }

    private func drawingGesture(in uiSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let start = value.startLocation.clamped(to: CGRect(origin: .zero, size: uiSize))
                let current = value.location.clamped(to: CGRect(origin: .zero, size: uiSize))
                currentRect = rect(from: start, to: current)
            }
            .onEnded { _ in
                guard let rect = currentRect, !fields.isEmpty else { return }
                let norm = normalize(rect: rect, in: uiSize)
                let key = fields[selectedFieldIndex].rawValue
                regions[key] = norm
                currentRect = nil
            }
    }

    private func normalize(rect: CGRect, in uiSize: CGSize) -> NormalizedRect {
        let x = max(0, min(1, rect.origin.x / uiSize.width))
        let y = max(0, min(1, rect.origin.y / uiSize.height))
        let w = max(0, min(1, rect.size.width / uiSize.width))
        let h = max(0, min(1, rect.size.height / uiSize.height))
        return NormalizedRect(x: x, y: y, width: w, height: h)
    }

    private func rect(from a: CGPoint, to b: CGPoint) -> CGRect {
        CGRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(b.x - a.x), height: abs(b.y - a.y))
    }

    private func fittedSize(for image: UIImage, in bounding: CGSize) -> CGSize {
        let iw = image.size.width
        let ih = image.size.height
        guard iw > 0, ih > 0 else { return bounding }
        let scale = min(bounding.width / iw, bounding.height / ih)
        return CGSize(width: iw * scale, height: ih * scale)
    }

    private func fieldColor(_ field: BadgeField) -> Color {
        switch field {
        case .name: return .blue
        case .company: return .green
        case .title: return .orange
        case .role: return .purple
        case .attendeeType: return .pink
        case .other: return .gray
        }
    }

    private func clearSelected() {
        guard !fields.isEmpty else { return }
        regions.removeValue(forKey: fields[selectedFieldIndex].rawValue)
    }

    private func fitToExisting() {
        // No-op placeholder for future enhancement (e.g., auto-detect text block near region)
    }
}

private extension CGPoint {
    func clamped(to rect: CGRect) -> CGPoint {
        CGPoint(x: max(rect.minX, min(rect.maxX, x)), y: max(rect.minY, min(rect.maxY, y)))
    }
}


