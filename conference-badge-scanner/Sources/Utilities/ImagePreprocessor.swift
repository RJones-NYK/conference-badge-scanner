import UIKit
import Vision
import CoreImage

enum ImagePreprocessor {
    static let ciContext = CIContext(options: nil)

    /// Preprocesses an image for OCR: fixes orientation, optionally applies perspective correction,
    /// and runs Core Image auto enhancements. Returns a new UIImage.
    static func preprocess(image: UIImage,
                           targetMaxDimension: CGFloat = 2200,
                           enablePerspectiveCorrection: Bool = true) -> UIImage {
        // 1) Normalize orientation
        let oriented = image.normalizedOrientation()

        // 2) Downscale to reasonable size while preserving quality
        let scaled = oriented.scaled(toMaxDimension: targetMaxDimension)

        // 3) Optionally try perspective correction (best-effort)
        let deskewed: UIImage
        if enablePerspectiveCorrection, let corrected = perspectiveCorrect(image: scaled) {
            deskewed = corrected
        } else {
            deskewed = scaled
        }

        // 4) Auto enhance with Core Image filters
        let enhanced = autoEnhance(image: deskewed) ?? deskewed

        return enhanced
    }

    private static func perspectiveCorrect(image: UIImage) -> UIImage? {
        guard let cg = image.cgImage else { return nil }
        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 1
        request.minimumConfidence = 0.6
        request.minimumAspectRatio = 0.3
        let handler = VNImageRequestHandler(cgImage: cg, options: [:])
        do {
            try handler.perform([request])
            guard let rect = (request.results?.first as? VNRectangleObservation) else { return nil }
            // Map Vision's normalized coordinates to image pixels
            let w = CGFloat(cg.width)
            let h = CGFloat(cg.height)

        // Vision's VNRectangleObservation uses a bottom-left origin, same as Core Image.
        // Do NOT invert Y when mapping to CI coordinates.
        func toPoint(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x * w, y: p.y * h) }

            let topLeft = toPoint(rect.topLeft)
            let topRight = toPoint(rect.topRight)
            let bottomLeft = toPoint(rect.bottomLeft)
            let bottomRight = toPoint(rect.bottomRight)

            let ciImage = CIImage(cgImage: cg)
            let filter = CIFilter(name: "CIPerspectiveCorrection")!
            filter.setValue(ciImage, forKey: kCIInputImageKey)
            filter.setValue(CIVector(cgPoint: topLeft), forKey: "inputTopLeft")
            filter.setValue(CIVector(cgPoint: topRight), forKey: "inputTopRight")
            filter.setValue(CIVector(cgPoint: bottomLeft), forKey: "inputBottomLeft")
            filter.setValue(CIVector(cgPoint: bottomRight), forKey: "inputBottomRight")

            guard let output = filter.outputImage,
                  let outCG = ciContext.createCGImage(output.oriented(.downMirrored), from: output.extent) else { return nil }
            // Correct for camera mirroring and orientation so saved image is upright.
            return UIImage(cgImage: outCG, scale: image.scale, orientation: .up)
        } catch {
            return nil
        }
    }

    private static func autoEnhance(image: UIImage) -> UIImage? {
        guard let cg = image.cgImage else { return nil }
        let ci = CIImage(cgImage: cg)
        // CIImageAutoAdjustmentOption.features expects an array of CIFeature objects, not a Bool.
        // Passing a Bool can crash internally when Core Image calls `count` on the value.
        // Omit features entirely or provide an empty array to disable.
        var options: [CIImageAutoAdjustmentOption: Any] = [
            CIImageAutoAdjustmentOption.enhance: true,
            CIImageAutoAdjustmentOption.redEye: false
        ]
        options[CIImageAutoAdjustmentOption.features] = [] as [Any]

        let filters = ci.autoAdjustmentFilters(options: options)
        let output = filters.reduce(ci) { current, filter in
            filter.setValue(current, forKey: kCIInputImageKey)
            return filter.outputImage ?? current
        }
        guard let outCG = ciContext.createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: outCG, scale: image.scale, orientation: .up)
    }
}

private extension UIImage {
    func normalizedOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }

    func scaled(toMaxDimension maxDim: CGFloat) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDim, maxSide > 0 else { return self }
        let scale = maxDim / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}


