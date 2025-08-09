import SwiftUI
import VisionKit

struct DocumentScannerView: UIViewControllerRepresentable {
    var onScanned: (UIImage, String) -> Void
    var onCancel: () -> Void
    // Allow callers to disable perspective correction when they want the full uncropped image
    var enablePerspectiveCorrection: Bool = true

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScanned: onScanned, onCancel: onCancel, enablePerspectiveCorrection: enablePerspectiveCorrection)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onScanned: (UIImage, String) -> Void
        let onCancel: () -> Void
        let enablePerspectiveCorrection: Bool

        init(onScanned: @escaping (UIImage, String) -> Void, onCancel: @escaping () -> Void, enablePerspectiveCorrection: Bool) {
            self.onScanned = onScanned
            self.onCancel = onCancel
            self.enablePerspectiveCorrection = enablePerspectiveCorrection
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            if Thread.isMainThread {
                onCancel()
            } else {
                DispatchQueue.main.async { self.onCancel() }
            }
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            if Thread.isMainThread {
                onCancel()
            } else {
                DispatchQueue.main.async { self.onCancel() }
            }
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            guard scan.pageCount > 0 else { onCancel(); return }
            // Heavy work off the main thread to prevent UI freezes while VisionKit view is dismissing
            let raw = scan.imageOfPage(at: 0)
            DispatchQueue.global(qos: .userInitiated).async {
                let image = ImagePreprocessor.preprocess(image: raw, enablePerspectiveCorrection: self.enablePerspectiveCorrection)
                OCRProcessor.recognizeText(in: image) { text in
                    // OCRProcessor already hops to main; just forward
                    self.onScanned(image, text)
                }
            }
        }
    }
}


