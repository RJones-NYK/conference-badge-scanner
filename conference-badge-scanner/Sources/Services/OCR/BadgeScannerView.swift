import SwiftUI
import VisionKit

struct BadgeScannerView: UIViewControllerRepresentable {
    var onText: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        try? controller.startScanning()
        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
        uiViewController.delegate = nil
    }

    func makeCoordinator() -> Coordinator { Coordinator(onText: onText) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onText: (String) -> Void
        init(onText: @escaping (String) -> Void) { self.onText = onText }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didAdd addedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            for item in addedItems {
                if case let .text(textItem) = item {
                    // RecognizedItem.Text exposes .transcript in iOS 17; fall back to description otherwise
                    let text = textItem.transcript
                    if !text.isEmpty {
                        if !text.isEmpty { onText(text) }
                    } else {
                        // As a last resort, use the debugDescription
                        let fallback = String(describing: textItem)
                        if !fallback.isEmpty { onText(fallback) }
                    }
                }
            }
        }
    }
}


