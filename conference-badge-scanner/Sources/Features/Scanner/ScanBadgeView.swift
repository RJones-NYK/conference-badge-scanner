import SwiftUI
import VisionKit
import SwiftData
import UIKit

struct ScanBadgeView: View {
    @Environment(\.dismiss) private var dismiss
    let event: Event?
    var onComplete: (UIImage?, String) -> Void
    var onCancel: () -> Void
    // Optional: return per-field OCR when template regions are available
    var onMapped: (([String: String]) -> Void)? = nil

    @State private var buffer: [String] = []
    @State private var useDocumentScanner = true
    @State private var scannedImage: UIImage? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if useDocumentScanner, VNDocumentCameraViewController.isSupported {
                    DocumentScannerView(onScanned: { image, text in
                        // Prefer document scanner OCR result
                        scannedImage = image
                        buffer = text.components(separatedBy: "\n").filter { !$0.isEmpty }
                        // If event provides template regions, try region OCR merge
                        if let img = scannedImage, let ev = event {
                            let map = ev.badgeFieldRegionsMap
                            guard !map.isEmpty else {
                                onComplete(image, text)
                                dismiss()
                                return
                            }
                            OCRProcessor.recognizeText(in: img, regionsByKey: map) { mapped in
                                // fire structured map callback if provided
                                onMapped?(mapped)
                                let merged = mergeRegionText(mapped: mapped, fallback: text, event: ev)
                                onComplete(image, merged)
                                dismiss()
                            }
                        } else {
                            onComplete(image, text)
                            dismiss()
                        }
                    }, onCancel: {
                        onCancel();
                        dismiss()
                    }, enablePerspectiveCorrection: false)
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
                            onComplete(nil, raw)
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
        .onChange(of: useDocumentScanner) { _, newValue in
            // Defensive: re-rendering toggles while a document camera is active can crash in iOS 17.
            // Delay switch until next runloop on main to let VisionKit settle.
            DispatchQueue.main.async { _ = newValue }
        }
    }

    private func mergeRegionText(mapped: [String: String], fallback: String, event: Event?) -> String {
        // Prefer event-selected field order if available; fallback to global order
        let orderedKeys: [String]
        if let event {
            orderedKeys = event.selectedBadgeFields.map { $0.rawValue }
        } else {
            orderedKeys = BadgeField.allCases.map { $0.rawValue }
        }
        var lines: [String] = []
        for key in orderedKeys {
            if let val = mapped[key], !val.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                lines.append(val)
            }
        }
        if lines.isEmpty { return fallback }
        return lines.joined(separator: "\n")
    }
}


