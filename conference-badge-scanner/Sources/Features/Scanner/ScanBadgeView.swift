import SwiftUI
import VisionKit

struct ScanBadgeView: View {
    @Environment(\.dismiss) private var dismiss
    var onComplete: (String) -> Void
    var onCancel: () -> Void

    @State private var buffer: [String] = []
    @State private var useDocumentScanner = true

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if useDocumentScanner, VNDocumentCameraViewController.isSupported {
                    DocumentScannerView { image, text in
                        // Prefer document scanner OCR result
                        buffer = text.components(separatedBy: "\n").filter { !$0.isEmpty }
                        onComplete(text)
                        dismiss()
                    } onCancel: {
                        onCancel();
                        dismiss()
                    }
                    .ignoresSafeArea()
                } else if ScannerAvailability.isSupported && ScannerAvailability.isAvailable {
                    BadgeScannerView { text in
                        buffer.append(text)
                        if buffer.count > 50 { buffer.removeFirst(buffer.count - 50) }
                    }
                    .ignoresSafeArea()
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.title)
                        Text("Scanner not available on this device.")
                        Text("If you recently denied access, enable Camera in Settings > Privacy & Security > Camera.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Button("Close") { onCancel(); dismiss() }
                    }
                }
            }

            if !useDocumentScanner {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Latest recognized:").font(.caption).foregroundStyle(.secondary)
                    ScrollView { Text(buffer.joined(separator: "\n")).font(.footnote).frame(maxWidth: .infinity, alignment: .leading) }
                    HStack {
                        Button("Cancel") { onCancel(); dismiss() }
                        Spacer()
                        Button {
                            let raw = buffer.joined(separator: "\n")
                            onComplete(raw)
                            dismiss()
                        } label: {
                            Label("Use Text", systemImage: "checkmark.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 16))
                .padding()
            }
        }
        .safeAreaInset(edge: .top) {
            HStack(spacing: 12) {
                Text(useDocumentScanner ? "Document Scanner" : "Live Text Scanner")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("", selection: $useDocumentScanner) {
                    Text("Doc").tag(true)
                    Text("Live").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.thinMaterial)
        }
    }
}


