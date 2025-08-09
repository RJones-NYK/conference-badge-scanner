import UIKit
import Vision

enum OCRProcessor {
    /// Recognize text from an image and return a single concatenated string.
    static func recognizeText(in image: UIImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage else { completion(""); return }

        let request = VNRecognizeTextRequest { request, _ in
            let results = (request.results as? [VNRecognizedTextObservation]) ?? []
            let strings: [String] = results.compactMap { $0.topCandidates(1).first?.string }
            // Always return on the main queue to avoid updating SwiftUI state from a background thread
            let output = strings.joined(separator: "\n")
            if Thread.isMainThread {
                completion(output)
            } else {
                DispatchQueue.main.async { completion(output) }
            }
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.minimumTextHeight = 0.02

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                if Thread.isMainThread {
                    completion("")
                } else {
                    DispatchQueue.main.async { completion("") }
                }
            }
        }
    }

    /// Recognize text and compute a composite confidence score (length-weighted average of line confidences).
    static func recognizeTextDetailed(in image: UIImage, completion: @escaping (String, Double) -> Void) {
        guard let cgImage = image.cgImage else { completion("", 0); return }

        let request = VNRecognizeTextRequest { request, _ in
            let results = (request.results as? [VNRecognizedTextObservation]) ?? []
            var lines: [String] = []
            var weighted: Double = 0
            var totalLen: Double = 0
            for obs in results {
                if let candidate = obs.topCandidates(1).first {
                    let text = candidate.string
                    lines.append(text)
                    let len = Double(text.count)
                    weighted += Double(candidate.confidence) * len
                    totalLen += len
                }
            }
            let output = lines.joined(separator: "\n")
            let confidence = totalLen > 0 ? max(0, min(1, weighted / totalLen)) : 0
            if Thread.isMainThread {
                completion(output, confidence)
            } else {
                DispatchQueue.main.async { completion(output, confidence) }
            }
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.minimumTextHeight = 0.02

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                if Thread.isMainThread {
                    completion("", 0)
                } else {
                    DispatchQueue.main.async { completion("", 0) }
                }
            }
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

    /// Recognize text and confidence inside a specific normalized rectangle region of the image.
    static func recognizeTextDetailed(in image: UIImage, region: NormalizedRect, completion: @escaping (String, Double) -> Void) {
        guard let cgImage = image.cgImage else { completion("", 0); return }

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let rect = CGRect(x: CGFloat(region.x) * width,
                          y: CGFloat(region.y) * height,
                          width: max(1, CGFloat(region.width) * width),
                          height: max(1, CGFloat(region.height) * height))
            .integral

        guard let cropped = cgImage.cropping(to: rect) else {
            completion("", 0)
            return
        }
        let croppedImage = UIImage(cgImage: cropped)
        recognizeTextDetailed(in: croppedImage, completion: completion)
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

    /// Recognize text and confidence for multiple regions and return mapping by field key.
    static func recognizeTextDetailed(in image: UIImage,
                                      regionsByKey: [String: NormalizedRect],
                                      completion: @escaping ([String: (String, Double)]) -> Void) {
        let group = DispatchGroup()
        var results: [String: (String, Double)] = [:]
        let lock = NSLock()

        for (key, region) in regionsByKey {
            group.enter()
            recognizeTextDetailed(in: image, region: region) { text, confidence in
                lock.lock(); results[key] = (text, confidence); lock.unlock()
                group.leave()
            }
        }
        group.notify(queue: .main) {
            completion(results)
        }
    }
}


