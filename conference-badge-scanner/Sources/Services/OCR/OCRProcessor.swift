import UIKit
import Vision

enum OCRProcessor {
    static func recognizeText(in image: UIImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage else { completion(""); return }

        let request = VNRecognizeTextRequest { request, _ in
            let results = (request.results as? [VNRecognizedTextObservation]) ?? []
            let strings: [String] = results.compactMap { $0.topCandidates(1).first?.string }
            completion(strings.joined(separator: "\n"))
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.minimumTextHeight = 0.02

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do { try handler.perform([request]) } catch { completion("") }
        }
    }
}


