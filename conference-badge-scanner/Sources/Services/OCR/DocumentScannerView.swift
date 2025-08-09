import SwiftUI
import VisionKit

struct DocumentScannerView: UIViewControllerRepresentable {
    var onScanned: (UIImage, String) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScanned: onScanned, onCancel: onCancel)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onScanned: (UIImage, String) -> Void
        let onCancel: () -> Void

        init(onScanned: @escaping (UIImage, String) -> Void, onCancel: @escaping () -> Void) {
            self.onScanned = onScanned
            self.onCancel = onCancel
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            onCancel()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            guard scan.pageCount > 0 else { onCancel(); return }
            // Use the first page by default
            let image = scan.imageOfPage(at: 0)
            OCRProcessor.recognizeText(in: image) { text in
                self.onScanned(image, text)
            }
        }
    }
}


