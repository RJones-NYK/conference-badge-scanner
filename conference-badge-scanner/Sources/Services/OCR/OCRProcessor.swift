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

    /// Recognize text inside a specific normalized rectangle region of the image.
    /// - Parameters:
    ///   - image: Source image
    ///   - region: NormalizedRect in [0,1] coordinate space (top-left origin)
    ///   - completion: Recognized text from that region
    static func recognizeText(in image: UIImage, region: NormalizedRect, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage else { completion(""); return }

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let rect = CGRect(x: CGFloat(region.x) * width,
                          y: CGFloat(region.y) * height,
                          width: max(1, CGFloat(region.width) * width),
                          height: max(1, CGFloat(region.height) * height))
            .integral

        guard let cropped = cgImage.cropping(to: rect) else {
            completion("")
            return
        }
        let croppedImage = UIImage(cgImage: cropped)
        recognizeText(in: croppedImage, completion: completion)
    }

    /// Recognize text for multiple regions and return a mapping by field key.
    static func recognizeText(in image: UIImage,
                              regionsByKey: [String: NormalizedRect],
                              completion: @escaping ([String: String]) -> Void) {
        let group = DispatchGroup()
        var results: [String: String] = [:]
        let lock = NSLock()

        for (key, region) in regionsByKey {
            group.enter()
            recognizeText(in: image, region: region) { text in
                lock.lock(); results[key] = text; lock.unlock()
                group.leave()
            }
        }
        group.notify(queue: .main) {
            completion(results)
        }
    }
}


