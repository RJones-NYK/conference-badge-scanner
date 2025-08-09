import SwiftUI
import VisionKit

struct BadgeScannerView: UIViewControllerRepresentable {
    var onText: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: false,
            isHighlightingEnabled: false
        )
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        // Start scanning once the controller is in a valid state (avoids early-start crashes)
        if !context.coordinator.hasStartedScanning {
            context.coordinator.hasStartedScanning = true
            DispatchQueue.main.async {
                try? uiViewController.startScanning()
            }
        }
    }

    func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
        uiViewController.delegate = nil
        coordinator.hasStartedScanning = false
    }

    func makeCoordinator() -> Coordinator { Coordinator(onText: onText) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var hasStartedScanning: Bool = false
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
                        if Thread.isMainThread {
                            onText(text)
                        } else {
                            DispatchQueue.main.async { self.onText(text) }
                        }
                    } else {
                        // As a last resort, use the debugDescription
                        let fallback = String(describing: textItem)
                        if !fallback.isEmpty {
                            if Thread.isMainThread {
                                onText(fallback)
                            } else {
                                DispatchQueue.main.async { self.onText(fallback) }
                            }
                        }
                    }
                }
            }
        }
    }
}


