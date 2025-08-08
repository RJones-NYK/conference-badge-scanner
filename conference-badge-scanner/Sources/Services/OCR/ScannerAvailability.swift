import VisionKit

@MainActor
enum ScannerAvailability {
    static var isSupported: Bool { DataScannerViewController.isSupported }
    static var isAvailable: Bool { DataScannerViewController.isAvailable }
}


